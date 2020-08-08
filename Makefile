###########################################################
# Makefile for compiling a conference / journal paper
# Author: Yuki Furuta <furushchev@jsk.imi.i.u-tokyo.ac.jp>
# Date: 2015/11/12
###########################################################

TARGET := main 

OS := $(shell uname -s)
VERSION := $(shell lsb_release -rs 2> /dev/null)
LATEXMK := $(shell command -v latexmk 2> /dev/null)
LATEXMK_OPTION := -time -recorder -rules
LATEXMK_EXEC := latexmk $(LATEXMK_OPTION)

.PHONY: all install preview forever publish pub clean wipe

all: install
	$(LATEXMK_EXEC) -pvc- $(TARGET)

preview: install
	$(LATEXMK_EXEC) -pv $(TARGET)

forever: install
	$(LATEXMK_EXEC) -pvc $(TARGET)

%.tex.orig: %.tex
	sed -i.orig -e's/、/，/g' -e's/。/．/g' $<
publish: $(addsuffix .orig, $(wildcard *.tex src/*.tex)) all
pub: publish

clean: install
	$(LATEXMK_EXEC) -c

wipe: install clean
	$(LATEXMK_EXEC) -C
	git clean -X -f -i -e '.tex' -e '.tex.orig'

install:
ifndef LATEXMK
	@echo 'installing components...'
ifeq ($(OS), Linux)
ifeq ($(VERSION), )
	$(error lsb-release is not installed)
else ifeq ($(VERSION), 12.04)
	sudo apt-get install -y -qq texlive texlive-lang-cjk texlive-science texlive-fonts-recommended texlive-fonts-extra xdvik-ja dvipsk-ja gv latexmk
else ifeq ($(VERSION), 14.04)
	sudo apt install -y -qq texlive texlive-lang-cjk texlive-science texlive-fonts-recommended texlive-fonts-extra xdvik-ja dvipsk-ja gv latexmk
else
	sudo apt install -y -qq texlive texlive-lang-cjk texlive-lang-japanese texlive-science texlive-fonts-recommended texlive-fonts-extra xdvik-ja gv latexmk
endif
endif
ifeq ($(OS), Darwin)
	brew tap caskroom/cask && brew cask install -v mactex && sudo tlmgr update --self --all
endif
endif

# upload settings
SSH_USER = k-kojima
YEAR = 2020
THESIS = rsj

UPLOADNAME = $(shell date +%s)
TARGET_DIR = $(THESIS)$(YEAR)
TARGET = main
BUILD_DIR = .
upload: $(BUILD_DIR)/$(TARGET)_s.pdf
	ssh $(SSH_USER)@www mkdir -p /home/jsk/$(SSH_USER)/public_html/Documents/$(TARGET_DIR)
	scp $< $(SSH_USER)@www:/home/jsk/$(SSH_USER)/public_html/Documents/$(TARGET_DIR)/$(SSH_USER)_$(TARGET_DIR)-$(UPLOADNAME).pdf
	ssh $(SSH_USER)@www ln -sf /home/jsk/$(SSH_USER)/public_html/Documents/$(TARGET_DIR)/$(SSH_USER)_$(TARGET_DIR)-$(UPLOADNAME).pdf /home/jsk/$(SSH_USER)/public_html/Documents/$(TARGET_DIR)/$(SSH_USER)_$(TARGET_DIR).pdf
	 # scp $< aries:/home/jsk/inaba/$(YEAR)/master/paper/$(SSH_USER)_$(TARGET_DIR).pdf

compress: $(BUILD_DIR)/$(TARGET)_s.pdf

$(BUILD_DIR)/$(TARGET)_s.pdf: $(BUILD_DIR)/$(TARGET).pdf
	$(MUTE)gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/prepress -dNOPAUSE -dQUIET -dBATCH -sOutputFile=$(BUILD_DIR)/$(TARGET)_gs.pdf $<
