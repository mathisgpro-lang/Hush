import subprocess,time,pathlib
udid='448DC48F-484B-45CD-86CC-89FFF3182EC6'
out=pathlib.Path('docs/design/flame-depth/verification/sanctuary-look'); out.mkdir(parents=True,exist_ok=True)
def run(*args): subprocess.run(args,check=True)
run('xcrun','simctl','install',udid,'/tmp/hush-depth-sim/Build/Products/Release-iphonesimulator/SpikeLab.app')
for direction in ['left','right','up','down','rest']:
 args=['xcrun','simctl','launch','--terminate-running-process',udid,'com.mathis.lifegamified.spikelab','-skipintro','-nogift','-form','beyond','-hour','16']
 if direction!='rest': args+=['-push',direction]
 run(*args); time.sleep(22)
 run('xcrun','simctl','io',udid,'screenshot',str(out/(direction+'.png')))
 print('CAPTURED',direction,flush=True)
