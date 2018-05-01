NB. build

writesourcex_jp_ '~Addons/data/jmf/source';'~Addons/data/jmf/jmf.ijs'

(jpath '~addons/data/jmf/jmf.ijs') (fcopynew ::0:) jpath '~Addons/data/jmf/jmf.ijs'

f=. 3 : 0
(jpath '~Addons/data/jmf/',y) fcopynew jpath '~Addons/data/jmf/source/',y
(jpath '~addons/data/jmf/',y) (fcopynew ::0:) jpath '~Addons/data/jmf/source/',y
)

mkdir_j_ jpath '~addons/data/jmf'
f 'manifest.ijs'
f 'history.txt'
f 'test/testdata.ijs'
f 'test/testjmf.ijs'
