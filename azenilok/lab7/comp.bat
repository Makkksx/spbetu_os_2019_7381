masm OVER1.asm OVER1.obj ;;
link OVER1.obj ;;
exe2bin.exe OVER1.exe OVER1.ovl
del OVER1.obj
del OVER1.exe

masm OVER2.asm OVER2.obj ;;
link OVER2.obj ;;
exe2bin.exe OVER2.exe OVER2.ovl
del OVER2.obj
del OVER2.exe

masm lab7.asm lab7.obj ;;
link lab7.obj ;;
del lab7.obj