taskkill /F /IM Intarocryptocurrency-qt.exe
mkdir "%USERPROFILE%"\Desktop\intarocryptocurrencybackup
cd "%USERPROFILE%"\Intarocryptocurrency\
del -r smsgStore
del -r smsgDB
del *.log
del smsg.ini
del blk*
del -r database
del -r txleveldb
del peers.dat
del mncache.dat
xcopy /E .\* "%USERPROFILE%"\Desktop\intarocryptocurrencybackup
