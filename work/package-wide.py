from pathlib import Path
import json,shutil
p=Path('prototypes/p2-spikes/SpikeLab');source=Path('docs/design/flame-depth/wider-worlds/surrounds')
header='// Generated from *-wide-surround.json by work/package-wide.py. Keep shader and mesh registration together.\n'
for name in ['sanctuary','grove','stillwater','highlands','forge','library','wilds']:
 d=json.loads((source/(name+'.json')).read_text())
 for ext in ['png','json']:shutil.copy2(source/(name+'.'+ext),p/'Assets'/(name+'-wide-surround.'+ext))
 vals=', '.join(f'{v:.9f}' for v in d['scale']+d['center'])
 impl='stageWorldImpl' if name=='sanctuary' else 'groveRestoreImpl'
 header+=f'[[visible]] void {name}WideWorld(realitykit::surface_parameters params) {{ {impl}(params, float4({vals})); }}\n'
(p/'WorldSurroundRegistration.h').write_text(header)
