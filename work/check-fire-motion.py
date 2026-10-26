from pathlib import Path
import subprocess,time
sim='448DC48F-484B-45CD-86CC-89FFF3182EC6';bundle='com.mathis.lifegamified.spikelab'
out=Path('docs/design/flame-depth/verification/fire-only');out.mkdir(parents=True,exist_ok=True)
subprocess.run(['xcrun','simctl','install',sim,'/tmp/hush-depth-sim/Build/Products/Release-iphonesimulator/SpikeLab.app'],check=True)
p=subprocess.Popen(['xcrun','simctl','launch','--terminate-running-process','--console-pty',sim,bundle,'-skipintro','-nogift','-form','beyond','-hour','16','-fps'],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
n=0
with (out/'simulator.log').open('w') as log:
 for line in p.stdout:
  log.write(line);log.flush()
  if 'SCREEN fps' not in line:continue
  n+=1
  if n>=5:
   subprocess.run(['xcrun','simctl','io',sim,'screenshot',str(out/f'frame-{n-5}.png')],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,check=True)
   print(f'Captured frame {n-5}',flush=True)
  if n>=9:p.terminate();break
