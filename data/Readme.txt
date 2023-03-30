Folder organization

NoisFre_dataset
-<CHIPID>
--<TEMPERATURE>
---TEST_<REPEATS>.bin

Data Collection Description

The bin file contains the start-up states of the whole 64 KiB SRAM block inside the nRF52832 Versatile Bluetooth 5.2 SoC.
An interested reader can find more detail about the evaluated chip in the datasheet in the root folder. 
The test was taken at three temperatures -15°C, 25°C and 80°C, with 100 repeats at each temperature.

Reference:
[1] Gao Y, Su Y, Nepal S, et al. "NoisFre: Noise-tolerant memory fingerprints from commodity devices for security functions." IEEE Transactions on Dependable and Secure Computing, Early Access, 2022.