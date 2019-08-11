#!/bin/sh

git clone https://bitbucket.org/genomicepidemiology/kma.git
cd kma/
# because `kma index...` still does not work in newer versions...
git checkout 1.1.7
make -j$(nproc)
sudo cp kma* /usr/local/bin/
cd
rm -rf kma/

git clone https://github.com/lh3/minimap2
cd minimap2 && make -j$(nproc)
sudo mv minimap2 /usr/local/bin/
sudo chmod 755 /usr/local/bin/minimap2
cd
rm -rf minimap2/

wget https://github.com/FelixKrueger/TrimGalore/archive/0.6.1.tar.gz
tar xzvf 0.6.1.tar.gz
sudo cp TrimGalore-0.6.1/trim_galore /usr/local/bin/
rm -rf TrimGalore-0.6.1/

sudo DEBIAN_FRONTEND=noninteractive apt-get install -o Dpkg::Options::='--force-confold' -f -u -y samtools

sudo -H pip install biopython cutadapt pysam
