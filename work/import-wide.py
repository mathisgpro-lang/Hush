from pathlib import Path
import shutil
names=['sanctuary','highlands','grove','forge','library','stillwater','wilds']
ids=['bcd74baf-4fae-431c-bb2b-28960adcab5e','8b48481e-b0b3-4b9c-999d-64c68bfcac99','f07a5713-00d7-47f6-9dce-68f96fef1f97','6cb29490-2e09-429a-a69b-44e5eb97d546','e74a9ee5-2fb2-4476-bc71-bff54e24f351','ed15a1cf-998e-40ff-90d0-9aec439eb475','8f978c08-555a-4cde-a963-537e212519bf']
for n,i in zip(names,ids):
 shutil.copy2(Path('/Users/mathis/.codex/generated_images/01a13acd-a3e2-7db3-8e48-9b5bf59cc49c')/('exec-'+i+'.png'),Path('docs/design/flame-depth/wider-worlds/surrounds')/(n+'.png'))
f=Path('work/register-worlds.py');f.write_text(f.read_text().replace('(.55,1.15)','(.35,.95)'))
