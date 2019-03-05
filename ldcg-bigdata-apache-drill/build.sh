#!/bin/bash

echo "deb http://obs.linaro.org/ERP:/18.06/Debian_9 ./" | sudo tee /etc/apt/sources.list.d/erp-18.06.list
echo "deb http://obs.linaro.org/ERP:/18.12/Debian_9 ./" | sudo tee /etc/apt/sources.list.d/erp-18.12.list

sudo apt -q=2 update
sudo apt -q=2 upgrade -y
sudo apt -q=2 install -y --no-install-recommends maven git openjdk-8-jdk-headless rpm

# Whole history is required
git clone https://git.linaro.org/leg/bigdata/drill.git

cd drill

mvn clean -X package -Pdeb -Prpm -DskipTests

cp distribution/target/apache-drill-*/*.deb out/
cp distribution/target/apache-drill-*/noarch/*.rpm out/

sudo chown -R buildslave:buildslave out
