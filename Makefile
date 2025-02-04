PROJECTNAME=colorclash

$(PROJECTNAME).gb: *.asm Engine/*.asm GameModes/*.asm Audio/*.asm Audio/Music/*.asm Audio/SFX/*.asm
	rgbasm -o $(PROJECTNAME).obj -p 255 Main.asm
	rgblink -p 255 -o $(PROJECTNAME).gbc -n $(PROJECTNAME).sym $(PROJECTNAME).obj
	rgbfix -v -p 255 $(PROJECTNAME).gbc
	
clean:
	find . -type f -name "*.gbc" -delete
	find . -type f -name "*.sym" -delete
	find . -type f -name "*.obj" -delete
	
