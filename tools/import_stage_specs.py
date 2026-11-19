#!/usr/bin/env python3
"""Transcribe authored GDD section 10 to committed JSON. Never used at runtime."""
import json
from pathlib import Path
import re
from decimal import Decimal, ROUND_HALF_UP

ROOT = Path(__file__).resolve().parents[1]

def ticks(value):
    return int((Decimal(str(value)) * 60).quantize(Decimal('1'), rounding=ROUND_HALF_UP))

def main():
    text = (ROOT / 'docs/VOID_LANTERN_GDD_v1.0.md').read_text()
    sections = re.split(r'^## (S\d\d) — (.+)$', text, flags=re.M)
    for i in range(1, len(sections), 3):
        sid, title, body = sections[i:i+3]
        body = body.split('# 11.')[0]
        speed = int(re.search(r'(?:скроллинга|Скорость)\s+(\d+)\s*px/s', body).group(1))
        profile = re.search(r'Профиль: `([^`]+)`', body).group(1)
        terrain = [[float(v) for v in triple.split(',')] for triple in re.findall(r'\(([^)]+)\)', profile)]
        hazards = []
        for n, (kind, args) in enumerate(re.findall(r'`(worldRect|oscRect|gate)\(([^)]+)\)`', body)):
            values = [float(v) for v in args.split(',')]
            h = {'id':f'{sid}:hazard:{n:03}', 'kind':kind, 'at_tick':ticks(values[0])}
            if kind == 'gate':
                _, w, y, gap, amp, period = values
                h.update(width=w, y=y, gap_height=gap, amplitude=amp, period=period)
            else:
                _, y, w, height, *rest = values
                h.update(width=w, y=y, height=height)
                if rest:
                    h.update(amplitude=rest[0], period=rest[1], phase=rest[2])
            hazards.append(h)
        events = []
        for line in body.splitlines():
            if not re.match(r'^\d+\s*\|', line):
                continue
            t, enemy, entry, y, count, gap, variant = [v.strip() for v in line.split('|')]
            if y.startswith('['):
                y = json.loads(y)
            elif y.startswith('corr('):
                y = {'corr':float(y[5:-1])}
            elif y.startswith('alt('):
                y = [float(v) for v in y[4:-1].split(',')]
            elif y == '-':
                y = None
            else:
                y = float(y)
            event = {'id':f'{sid}:{len(events):03}', 'at_tick':ticks(t), 'enemy':enemy,
                     'entry':entry, 'y':y, 'count':int(count), 'gap_ticks':ticks(gap)}
            if variant.startswith('drop='):
                event['drop'] = variant[5:]
            elif enemy == 'PICKUP':
                event['pickup'] = variant
            elif variant != '-':
                event['variant'] = variant
            events.append(event)
        beams = []
        beam_times = {'S07':[(18,94),(47,250),(70,146),(105,230)], 'S08':[(18,230),(88,132)]}
        for n, (t,y) in enumerate(beam_times.get(sid, [])):
            beams.append({'id':f'{sid}:beam:{n:03}','at_tick':ticks(t),'y':y,'width':16,
                          'warning_ticks':72,'active_ticks':33 if sid == 'S07' else 30,'x':640})
        result = {'schema_version':1,'id':sid,'name':title.split(' / ')[0].title(),
                  'scroll_speed':speed,'duration_ticks':7200,'checkpoints_ticks':[0,2400,4800,7200],
                  'terrain':terrain,'hazards':hazards,'events':events,'beams':beams,'boss':'B'+sid[1:]}
        path = ROOT / 'data/stages' / (sid.lower()+'.json')
        path.write_text(json.dumps(result,indent=2)+'\n')
        print(f'{sid}: {len(events)} rows, {sum(e["count"] for e in events)} entities, {len(hazards)} solids, {len(beams)} beams')

if __name__ == '__main__':
    main()
