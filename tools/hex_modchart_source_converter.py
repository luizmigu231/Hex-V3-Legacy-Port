#!/usr/bin/env python3
"""Convert Hex V3 ModChart Haxe source into lightweight Legacy cue JSON files.

Usage (Termux):
  python3 hex_modchart_source_converter.py --output /path/to/content/hex-v3-legacy-port

The converter fetches the seven chart sources from the public Hex-V3 main branch.
It preserves literal to()/jump() events, expands simple numeric loops, and approximates
hook-based every() blocks with cue pulses. It is not a Haxe interpreter; expressions or
hooks it cannot faithfully translate are listed in HEX_MODCHART_CONVERSION_REPORT.json.
"""
from __future__ import annotations
import argparse, ast, json, math, re, sys, urllib.request
from pathlib import Path
from typing import Any

BASE = "https://raw.githubusercontent.com/Kade-github/Hex-V3/main/"
SOURCE_ROOT: Path | None = None
CHARTS = {
    "eye2eye": "cppia-charts/kade/hex/modchart/charts/Eye2EyeModchart.hx",
    "detected": "cppia-charts/kade/hex/modchart/charts/DetectedModchart.hx",
    "detected_normal": "cppia-charts/kade/hex/modchart/charts/DetectedModchartNormal.hx",
    "headbasher": "cppia-charts/kade/hex/modchart/charts/HeadbasherModchart.hx",
    "rightpace": "cppia-charts/kade/hex/modchart/charts/RightPaceModchart.hx",
    "tangerine": "cppia-charts/kade/hex/modchart/charts/TangerineModchart.hx",
    "tangerine_normal": "cppia-charts/kade/hex/modchart/charts/TangerineModchartNormal.hx",
}
EASES = {"linear", "instant", "insine", "outsine", "inoutsine", "incubic", "outcubic", "inoutcubic", "inquad", "outquad", "inoutquad", "inexpo", "outexpo", "inoutexpo", "inback", "outback", "inoutback", "inelastic", "outelastic", "inoutelastic", "arc"}


def fetch(path: str) -> str:
    if SOURCE_ROOT is not None:
        local = SOURCE_ROOT / path
        if local.is_file():
            return local.read_text(encoding="utf-8-sig")
    req = urllib.request.Request(BASE + path, headers={"User-Agent": "HexV3-Legacy-Modchart-Converter/0.5"})
    with urllib.request.urlopen(req, timeout=25) as r:
        return r.read().decode("utf-8")



def strip_comments(src: str) -> str:
    out=[]; i=0; quote=None; esc=False; line=False; block=False
    while i<len(src):
        ch=src[i]; nxt=src[i+1] if i+1<len(src) else ''
        if line:
            if ch=='\n': line=False; out.append(ch)
            else: out.append(' ')
            i+=1; continue
        if block:
            if ch=='*' and nxt=='/': out.extend([' ',' ']); block=False; i+=2; continue
            out.append('\n' if ch=='\n' else ' '); i+=1; continue
        if quote:
            out.append(ch)
            if esc: esc=False
            elif ch=='\\': esc=True
            elif ch==quote: quote=None
            i+=1; continue
        if ch in ('\"', "'"): quote=ch; out.append(ch); i+=1; continue
        if ch=='/' and nxt=='/': out.extend([' ',' ']); line=True; i+=2; continue
        if ch=='/' and nxt=='*': out.extend([' ',' ']); block=True; i+=2; continue
        out.append(ch); i+=1
    return ''.join(out)

def match_close(s: str, start: int, op: str, cl: str) -> int:
    depth = 0; quote = None; esc = False; line_comment = False; block_comment = False; i = start
    while i < len(s):
        c = s[i]; n = s[i+1] if i+1 < len(s) else ""
        if line_comment:
            if c == "\n": line_comment = False
            i += 1; continue
        if block_comment:
            if c == "*" and n == "/": block_comment = False; i += 2; continue
            i += 1; continue
        if quote:
            if esc: esc = False
            elif c == "\\": esc = True
            elif c == quote: quote = None
            i += 1; continue
        if c == "/" and n == "/": line_comment = True; i += 2; continue
        if c == "/" and n == "*": block_comment = True; i += 2; continue
        if c in ('"', "'"): quote = c; i += 1; continue
        if c == op: depth += 1
        elif c == cl:
            depth -= 1
            if depth == 0: return i
        i += 1
    return -1


def split_top(s: str) -> list[str]:
    out=[]; start=0; stack=[]; quote=None; esc=False; i=0
    pairs={')':'(',']':'[','}':'{'}
    while i<len(s):
        c=s[i]
        if quote:
            if esc: esc=False
            elif c=='\\': esc=True
            elif c==quote: quote=None
            i+=1; continue
        if c in ('"',"'"): quote=c
        elif c in '([{': stack.append(c)
        elif c in ')]}':
            if stack and stack[-1]==pairs[c]: stack.pop()
        elif c==',' and not stack:
            out.append(s[start:i].strip()); start=i+1
        i+=1
    tail=s[start:].strip()
    if tail: out.append(tail)
    return out


def replace_code_tokens(s: str, name: str, value: str) -> str:
    # Substitute a loop variable without touching string literals or comments.
    out=[]; i=0; quote=None; esc=False; line_comment=False; block_comment=False
    while i<len(s):
        c=s[i]; n=s[i+1] if i+1<len(s) else ""
        if line_comment:
            out.append(c)
            if c=='\n': line_comment=False
            i+=1; continue
        if block_comment:
            out.append(c)
            if c=='*' and n=='/': out.append(n); block_comment=False; i+=2; continue
            i+=1; continue
        if quote:
            out.append(c)
            if esc: esc=False
            elif c=='\\': esc=True
            elif c==quote: quote=None
            i+=1; continue
        if c=='/' and n=='/': out.extend([c,n]); line_comment=True; i+=2; continue
        if c=='/' and n=='*': out.extend([c,n]); block_comment=True; i+=2; continue
        if c in ('"',"'"): quote=c; out.append(c); i+=1; continue
        if c.isalpha() or c=='_':
            j=i+1
            while j<len(s) and (s[j].isalnum() or s[j]=='_'): j+=1
            token=s[i:j]; out.append(value if token==name else token); i=j; continue
        out.append(c); i+=1
    return ''.join(out)


def expand_simple_loops(src: str, report: dict[str, Any]) -> str:
    # Expand simple for(i in 0...N) blocks, including a constant N.
    constants={}
    for m in re.finditer(r'(?:static\s+)?(?:inline\s+)?var\s+(\w+)\s*:\s*(?:Int|Float)\s*=\s*(-?\d+(?:\.\d+)?)',src):
        constants[m.group(1)]=float(m.group(2))
    for _ in range(5):
        found=False
        pattern=re.compile(r'for\s*\(\s*(\w+)\s+in\s+(-?\d+)\s*\.\.\.\s*(\w+|-?\d+)\s*\)\s*\{')
        for m in list(pattern.finditer(src))[::-1]:
            var,lo,end=m.group(1),int(m.group(2)),m.group(3)
            hi=int(constants[end]) if end in constants else (int(end) if re.fullmatch(r'-?\d+',end) else None)
            if hi is None: continue
            op=m.end()-1; close=match_close(src,op,'{','}')
            if close<0: continue
            body=src[op+1:close]
            expanded='\n'.join(replace_code_tokens(body,var,str(v)) for v in range(lo,hi))
            src=src[:m.start()]+expanded+src[close+1:]; found=True
        if not found: break
    # Expand simple while loops: var i=352; while (i <= 383) { body; i += 4; }
    for _ in range(6):
        found=False
        pattern=re.compile(r'(?:var\s+)?(\w+)\s*:\s*(?:Float|Int)\s*=\s*(-?\d+(?:\.\d+)?)\s*;\s*while\s*\(\s*\1\s*(<=|<|>=|>)\s*(-?\d+(?:\.\d+)?)\s*\)\s*\{')
        for m in list(pattern.finditer(src))[::-1]:
            var=float(m.group(2)); opcmp=m.group(3); limit=float(m.group(4)); brace=m.end()-1; close=match_close(src,brace,'{','}')
            if close<0: continue
            body=src[brace+1:close]
            inc=re.search(r'\b'+re.escape(m.group(1))+r'\s*\+=\s*(-?\d+(?:\.\d+)?)\s*;?',body)
            if not inc: continue
            step=float(inc.group(1)); body=re.sub(r'\b'+re.escape(m.group(1))+r'\s*\+=\s*-?\d+(?:\.\d+)?\s*;?', '', body)
            if step==0: continue
            expanded=[]; guard=0; cur=var
            def ok(x:float)->bool:
                return x<=limit if opcmp=='<=' else x<limit if opcmp=='<' else x>=limit if opcmp=='>=' else x>limit
            while ok(cur) and guard<2000:
                expanded.append(replace_code_tokens(body,m.group(1),str(cur)))
                cur+=step; guard+=1
            if guard>=2000: report.setdefault('warnings',[]).append('loop expansion limit reached')
            src=src[:m.start()]+'\n'.join(expanded)+src[close+1:]; found=True
        if not found: break
    return src


def parse_literal(raw: str, constants: dict[str,float], report: dict[str,Any]) -> Any:
    x=raw.strip()
    if not x: return None
    if x[0:1] in ('"',"'") and x[-1:]==x[0]: return x[1:-1]
    if x.lower() in ('true','false'): return x.lower()=='true'
    if re.fullmatch(r'-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?',x): return float(x) if any(c in x for c in '.eE') else int(x)
    # Convert Haxe easing function references to stable names.
    em=re.search(r'(?:self\.)?(inOutCubic|inCubic|outCubic|inOutSine|inSine|outSine|inExpo|outExpo|inOutExpo|inBack|outBack|inOutBack|inElastic|outElastic|inOutElastic|inOutQuad|inQuad|outQuad|linear|instant|arc)',x,re.I)
    if em: return em.group(1).lower()
    xm=re.fullmatch(r'(?:self\.)?xmod\(\s*(-?\d+(?:\.\d+)?)\s*\)',x,re.I)
    if xm: return float(xm.group(1))*100
    # Resolve constants and arithmetic with a restricted Python AST (no eval/attributes/calls).
    expr=x.replace('self.','').replace('Math.PI',str(math.pi))
    for key,val in sorted(constants.items(),key=lambda kv:-len(kv[0])):
        expr=re.sub(r'\b'+re.escape(key)+r'\b',str(val),expr)
    expr=re.sub(r'\b(?:true|false)\b','0',expr,flags=re.I)
    try:
        tree=ast.parse(expr,mode='eval')
        def ev(n):
            if isinstance(n,ast.Expression): return ev(n.body)
            if isinstance(n,ast.Constant) and isinstance(n.value,(int,float)): return float(n.value)
            if isinstance(n,ast.UnaryOp) and isinstance(n.op,(ast.UAdd,ast.USub)): return +ev(n.operand) if isinstance(n.op,ast.UAdd) else -ev(n.operand)
            if isinstance(n,ast.BinOp) and isinstance(n.op,(ast.Add,ast.Sub,ast.Mult,ast.Div,ast.Pow,ast.Mod)):
                a,b=ev(n.left),ev(n.right)
                if isinstance(n.op,ast.Add): return a+b
                if isinstance(n.op,ast.Sub): return a-b
                if isinstance(n.op,ast.Mult): return a*b
                if isinstance(n.op,ast.Div): return a/b if b else 0
                if isinstance(n.op,ast.Pow): return a**b
                return a%b if b else 0
            raise ValueError('unsupported expression')
        value=ev(tree)
        if math.isfinite(value): return value
    except Exception:
        pass
    report.setdefault('unsupportedExpressions',[]).append(x)
    return None


def parse_options(tail: str, constants: dict[str,float], report: dict[str,Any]) -> dict[str,Any]:
    opts={}
    if not tail: return opts
    # Only the first options object matters; parse plr/from in the Haxe object literal.
    plr=re.search(r'\bplr\s*:\s*(\[[^\]]*\]|-?\d+)',tail)
    if plr:
        if plr.group(1).startswith('['):
            opts['plr']=[int(float(x.strip())) for x in plr.group(1)[1:-1].split(',') if x.strip() and re.fullmatch(r'-?\d+(?:\.\d+)?',x.strip())]
        else: opts['plr']=int(plr.group(1))
    only=re.search(r'only\(\s*(-?\d+)\s*\)',tail)
    if only and 'plr' not in opts: opts['plr']=int(only.group(1))
    fr=re.search(r'\bfrom\s*:\s*([^,}\]]+)',tail)
    if fr: opts['from']=parse_literal(fr.group(1),constants,report)
    return opts


def get_calls(src: str, names: tuple[str,...]) -> list[tuple[str,str]]:
    out=[]
    pattern=re.compile(r'(?<![\w$])(?:self\s*\.\s*)?('+'|'.join(names)+r')\s*\(',re.I)
    for m in pattern.finditer(src):
        openp=src.find('(',m.start()); close=match_close(src,openp,'(',')')
        if close<0: continue
        out.append((m.group(1).lower(),src[openp+1:close]))
    return out


def cue_rows(source: str, chart_key: str, report: dict[str,Any]) -> list[list[Any]]:
    source=expand_simple_loops(strip_comments(source),report)
    constants={'PX':1.0,'LANE':112.0,'GAP':640.0,'BASEX':0.0,'MIDX':640.0,'WRAP_EDGE':140.0,'WRAP_PERIOD':1420.0,'WRAP_SPREAD':710.0,'WRAP_STEP':177.5,'HOME':1.0,'LIFT_ROW':100.0,'SHOVE_ROW':100.0,'HIDDEN_UNIT':239.7}
    for m in re.finditer(r'(?:static\s+)?(?:inline\s+)?var\s+(\w+)\s*:\s*(?:Int|Float)\s*=\s*(-?\d+(?:\.\d+)?)',source): constants[m.group(1)]=float(m.group(2))
    rows=[]
    # setup() base values establish each chart's starting state.
    setup_start=source.find('override function setup()')
    build_start=source.find('override function build()')
    setup=source[setup_start:build_start] if setup_start>=0 and build_start>setup_start else source[:max(0,build_start)]
    for kind,call in get_calls(setup,('base',)):
        arrpos=call.find('[')
        if arrpos<0: continue
        arrend=match_close(call,arrpos,'[',']')
        if arrend<0: continue
        vals=split_top(call[arrpos+1:arrend])
        if len(vals)>=2:
            val=parse_literal(vals[0],constants,report); name=parse_literal(vals[1],constants,report)
            if isinstance(name,str) and isinstance(val,(int,float)): rows.append([0,0,0,float(val),name,-1,'linear'])
    # Scan all methods, not only build(): Hex exports named helper layers after build().
    seen=set()
    for kind,call in get_calls(source,('to','jump')):
        arrpos=call.find('[')
        if arrpos<0: continue
        arrend=match_close(call,arrpos,'[',']')
        if arrend<0: continue
        vals=split_top(call[arrpos+1:arrend])
        tail=call[arrend+1:]
        opts=parse_options(tail,constants,report)
        if kind=='to':
            if len(vals)<5: continue
            start=parse_literal(vals[0],constants,report); duration=parse_literal(vals[1],constants,report); ease=parse_literal(vals[2],constants,report)
            pairs=vals[3:]
            if not isinstance(start,(int,float)) or not isinstance(duration,(int,float)): continue
            ease=str(ease or 'linear').lower().replace('inout','inout')
            for i in range(0,len(pairs)-1,2):
                target=parse_literal(pairs[i],constants,report); channel=parse_literal(pairs[i+1],constants,report)
                if not isinstance(target,(int,float)) or not isinstance(channel,str): continue
                fr=opts.get('from',None)
                players=opts.get('plr',-1); players=players if isinstance(players,list) else [players]
                for player in players:
                    row=[float(start),max(0,float(duration)),None if fr is None else float(fr),float(target),channel,int(player),ease]
                    key=tuple(row)
                    if key not in seen: rows.append(row); seen.add(key)
        else:
            if len(vals)<3: continue
            start=parse_literal(vals[0],constants,report)
            if not isinstance(start,(int,float)): continue
            pairs=vals[1:]
            for i in range(0,len(pairs)-1,2):
                target=parse_literal(pairs[i],constants,report); channel=parse_literal(pairs[i+1],constants,report)
                if not isinstance(target,(int,float)) or not isinstance(channel,str): continue
                players=opts.get('plr',-1); players=players if isinstance(players,list) else [players]
                for player in players:
                    row=[float(start),0,None,float(target),channel,int(player),'instant']
                    key=tuple(row)
                    if key not in seen: rows.append(row); seen.add(key)
    # Approximate hook-driven every() blocks as low-cost pulses. Their exact Hex hooks need native 3D behavior.
    hook_rows=[]
    for kind,call in get_calls(source,('every',)):
        arrpos=call.find('[')
        if arrpos<0: continue
        arrend=match_close(call,arrpos,'[',']')
        if arrend<0: continue
        vals=split_top(call[arrpos+1:arrend])
        if len(vals)<3: continue
        start=parse_literal(vals[0],constants,report); span=parse_literal(vals[1],constants,report); hook=parse_literal(vals[2],constants,report)
        if not isinstance(start,(int,float)) or not isinstance(span,(int,float)) or not isinstance(hook,str): continue
        args=[]
        if len(vals)>3 and vals[3].startswith('['):
            args=[parse_literal(x,constants,report) for x in split_top(vals[3][1:-1])]
        end=float(start)+max(0,float(span)); channel=None; peak=0
        if hook.lower()=='sway': channel='sway'; peak=float(args[0]) if args and isinstance(args[0],(int,float)) else 40
        elif hook.lower()=='wrap': channel='wrap'; peak=100
        elif hook.lower()=='step': channel='flipRow'; peak=100
        elif hook.lower()=='halo': channel='halo'; peak=100
        elif hook.lower()=='camrock': channel='cam.rotZ'; peak=8
        elif hook.lower()=='ring': channel='pinch'; peak=35
        elif hook.lower() in ('easydrunk','easydrunk'): channel='easydrunk'; peak=35
        else:
            report.setdefault('unsupportedHooks',[]).append({'chart':chart_key,'hook':hook,'start':start,'span':span})
        if channel:
            rows.append([float(start),0,0,peak,channel,-1,'linear'])
            rows.append([end,1,peak,0,channel,-1,'outsine'])
            hook_rows.append({'hook':hook,'start':start,'span':span,'approximation':channel})
    # Expand broadcast targets so each Legacy player has an independent tween start value.
    expanded=[]
    for row in rows:
        if int(row[5]) < 0:
            for p in (0,1):
                copy=row.copy(); copy[5]=p; expanded.append(copy)
        else:
            copy=row.copy(); copy[5]=int(copy[5]) % 2; expanded.append(copy)
    # Collapse source fields 0/2 and 1/3 when they map to the same Legacy field and event.
    deduped=[]; seen_mapped={}
    for row in expanded:
        key=(row[0],row[1],row[3],row[4],row[5],row[6])
        if key not in seen_mapped:
            seen_mapped[key]=len(deduped); deduped.append(row)
        elif deduped[seen_mapped[key]][2] is None and row[2] is not None:
            deduped[seen_mapped[key]][2]=row[2]
    rows=deduped
    rows.sort(key=lambda r:(r[0],r[4],r[5]))
    # Fill implicit `from` values from the latest prior state for each target.
    states:dict[tuple[str,int],float]={}
    for row in rows:
        start,duration,fr,to,channel,player,ease=row
        key=(channel,int(player))
        if fr is None: row[2]=states.get(key,0.0)
        states[key]=float(to)
    report.setdefault('chartStats',{})[chart_key]={'cueRows':len(rows),'uniqueChannels':len(set(r[4] for r in rows)),'approximatedEveryHooks':hook_rows}
    return rows


def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument('--output',default='.',help='Mod root (the folder containing scripts/, stages/, songs/)')
    ap.add_argument('--source',default=None,help='Optional extracted Hex-V3 repository root; charts are read locally when available')
    ap.add_argument('--skip-eye2eye',action='store_true',help='Skip Eye2Eye cue JSON because the dedicated eye2eye.hx runtime owns its timeline')
    args=ap.parse_args(); root=Path(args.output).expanduser().resolve(); dest=root/'data'/'modcharts'; dest.mkdir(parents=True,exist_ok=True)
    global SOURCE_ROOT
    SOURCE_ROOT=Path(args.source).expanduser().resolve() if args.source else None
    report:dict[str,Any]={'source':'https://github.com/Kade-github/Hex-V3/tree/main/cppia-charts/kade/hex/modchart/charts','sourceRoot':str(SOURCE_ROOT) if SOURCE_ROOT else None,'warnings':[],'unsupportedExpressions':[],'unsupportedHooks':[],'chartStats':{}}
    for key,path in CHARTS.items():
        if key=='eye2eye' and args.skip_eye2eye:
            report['chartStats'][key]={'skipped':'dedicated Eye2Eye song script already has its own timeline; omit --skip-eye2eye to export for analysis'}
            continue
        try: src=fetch(path)
        except Exception as e:
            report['warnings'].append({'chart':key,'error':str(e)}); continue
        rows=cue_rows(src,key,report)
        (dest/f'{key}.json').write_text(json.dumps(rows,separators=(',',':'),ensure_ascii=False)+'\n',encoding='utf-8')
    report['unsupportedExpressions']=sorted(set(report['unsupportedExpressions']))
    (root/'HEX_MODCHART_CONVERSION_REPORT.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    print('ModCharts exportados para:',dest)
    for k,v in report['chartStats'].items(): print(f"- {k}: {v.get('cueRows',v.get('skipped','sem saída'))}")
    print('Expressões sem tradução:',len(report['unsupportedExpressions']),'hooks aproximados/não suportados:',len(report['unsupportedHooks']))
    print('Relatório:',root/'HEX_MODCHART_CONVERSION_REPORT.json')
    return 0 if not report['warnings'] else 1

if __name__=='__main__': raise SystemExit(main())
