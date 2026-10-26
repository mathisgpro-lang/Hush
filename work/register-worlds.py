from pathlib import Path
from PIL import Image
import numpy as np,json,sys
from scipy.ndimage import map_coordinates,gaussian_filter
from scipy.optimize import differential_evolution
assets=Path('prototypes/p2-spikes/SpikeLab/Assets'); out=Path('docs/design/flame-depth/wider-worlds/surrounds')
for name in sys.argv[1:]:
 src=assets/('stage-home-paint.png' if name=='sanctuary' else name+'-world-paint.png')
 A=np.array(Image.open(src).convert('RGB').resize((120,260)),dtype=float)/255
 B=np.array(Image.open(out/(name+'.png')).convert('RGB').resize((720,540)),dtype=float)/255
 A=gaussian_filter(A,(.7,.7,0));B=gaussian_filter(B,(.8,.8,0))
 y,x=np.meshgrid(np.linspace(0,1,A.shape[0]),np.linspace(0,1,A.shape[1]),indexing='ij')
 def score(p):
  sx,sy,cx,cy=p;xx=((x-.5)*sx+cx)*(B.shape[1]-1);yy=((y-.5)*sy+cy)*(B.shape[0]-1)
  C=np.stack([map_coordinates(B[:,:,k],[yy,xx],order=1) for k in range(3)],axis=-1)
  return np.mean((C-A)**2)
 r=differential_evolution(score,[(.20,.60),(.35,.95),(.42,.58),(.42,.65)],seed=7,popsize=9,maxiter=100,tol=.0001)
 sx,sy,cx,cy=map(float,r.x);d=dict(scale=[sx,sy],center=[cx,cy],error=r.fun)
 (out/(name+'.json')).write_text(json.dumps(d,indent=2))
 print(name,d,flush=True)
