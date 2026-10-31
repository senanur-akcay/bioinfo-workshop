#datalar elimizde var mi diye kontrol edelim
ls -lh data/filtered_gene_bc_matrices/hg19/
head -3 data/filtered_gene_bc_matrices/hg19/genes.tsv
head -3 data/filtered_gene_bc_matrices/hg19/barcodes.tsv
head -5 data/filtered_gene_bc_matrices/hg19/matrix.mtx


git add scripts/
git commit -m "Day 2: single-cell"
git push
git log --oneline
git status

git add scripts/
git commit -m "Day 2: single-cell"
git push
git log --oneline
git status