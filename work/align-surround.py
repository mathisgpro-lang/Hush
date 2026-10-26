from PIL import Image
import numpy as np
from scipy.ndimage import map_coordinates, gaussian_filter
from scipy.optimize import differential_evolution
A=np.array(Image.open('docs/design/flame-depth/live/sanctuary-stage.png').convert('RGB').resize((170,369)),dtype=float)/255
B=np.array(Image.open('docs/design/flame-depth/live/sanctuary-surround.png').convert('RGB'),dtype=float)/255
A=gaussian_filter(A,(1,1,0)); B=gaussian_filter(B,(2,2,0))
y,x=np.meshgrid(np.linspace(0,1,A.shape[0]),np.linspace(0,1,A.shape[1]),indexing='ij')
def score(p):
 sx,sy,cx,cy=p
 xx=((x-.5)*sx+cx)*(B.shape[1]-1); yy=((y-.5)*sy+cy)*(B.shape[0]-1)
 C=np.stack([map_coordinates(B[:,:,k],[yy,xx],order=1) for k in range(3)],axis=-1)
 return np.mean((C-A)**2)
r=differential_evolution(score,[(.42,.65),(.5,.8),(.46,.54),(.46,.54)],popsize=9,maxiter=80,tol=.0001)
print('sx sy cx cy:',r.x,'error:',r.fun, flush=True)
