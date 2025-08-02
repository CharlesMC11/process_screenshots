SCRIPT_NAME := process_screenshots
BIN_PATH    := ~/.local/bin/$(SCRIPT_NAME)

symlink     := install -v -l as

all:  main workflow

main: main.sh.zwc dir
	$(symlink) $@.sh $(BIN_PATH)/$@
	$(symlink) $< $(BIN_PATH)/$@.zwc
	chmod +x $(BIN_PATH)/$@

workflow: workflow.sh.zwc $(SCRIPT_NAME).workflow dir
	$(symlink) $(SCRIPT_NAME).workflow ~/Library/Workflows/Applications/Folder\ Actions/$<

	$(symlink) $@.sh $(BIN_PATH)/$@.sh
	$(symlink) $< $(BIN_PATH)/$<

%.sh.zwc: %.sh
	zsh -c 'zcompile $<'

dir:
	if [ -d $(BIN_PATH) ]; then exit 0;\
	elif [ -e $(BIN_PATH) ]; then rm $(BIN_PATH);\
	fi;\
	mkdir $(BIN_PATH)
