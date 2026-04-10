#!/bin/bash

RELPATH="$(dirname "$0")"
STARTPATH="$(pwd)"
OWNPATH="$(cd "$RELPATH"; pwd)"

cd "${OWNPATH}"

rm -r "${OWNPATH}/input-latex"
mkdir -p "${OWNPATH}/input-latex"

cp -v "${OWNPATH}/paper/paper.tex" "${OWNPATH}/input-latex/paper.txt"
cp -v "${OWNPATH}/paper/paper.pdf" "${OWNPATH}/input-latex/paper.pdf"
cp -v "${OWNPATH}/plan.txt" "${OWNPATH}/input-latex/plan.txt"
cp -v "${OWNPATH}/slides/presentation.tex" "${OWNPATH}/input-latex/presentation.tex"

cd "${OWNPATH}/slides"
pdflatex presentation.tex
pdflatex presentation.tex

cp -v "${OWNPATH}/slides/presentation.pdf" "${OWNPATH}/input-latex/presentation.pdf
