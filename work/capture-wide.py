from pathlib import Path
import subprocess,os
sim='448DC48F-484B-45CD-86CC-89FFF3182EC6'
out=Path('docs/design/flame-depth/verification/wider-worlds');out.mkdir(parents=True,exist_ok=True)
container=subprocess.check_output(['xcrun','simctl','get_app_container',sim,'com.mathis.lifegamified.spikelab','data'],text=True).strip()
ack=Path(container)/'Documents'/'framing-next'
p=subprocess.Popen(['xcrun','simctl','launch','--terminate-running-process','--console-pty',sim,'com.mathis.lifegamified.spikelab','-skipintro','-nogift','-form','beyond','-hour','16','-framingcheck','-fps'],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,bufsize=1)
with (out/'simulator.log').open('w') as log:
 for line in p.stdout:
  log.write(line);log.flush()
  if 'FRAME_CAPTURE ' in line:
   words=line.split('FRAME_CAPTURE ',1)[1].split();name,pose=words[:2]
   subprocess.run(['xcrun','simctl','io',sim,'screenshot',str(out/(name+'-'+pose+'.png'))],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
   ack.touch()
   print(line.strip(),flush=True)
   if os.environ.get("HUSH_FRAMING_ONLY")==name and pose=="right-down":
    p.terminate();break
  if 'FRAMING_CHECK_DONE' in line:
   p.terminate();break
