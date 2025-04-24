#  Ice or Snow Surface Temperature Retrieval Algorithm for SDGSAT-1

This repository contains an algorithm for retrieving Ice or Snow surface temeprature (IST) based on SDGSAT-1 satellite data. The algorithm leverages four Splited-Window Algorithms (SWAs) for IST retrieval, which include:

- **PR1984**: 
- **VI1991**:
- **UL1994**: 
- **Enter2019**:

These methods are commonly used in remote sensing for surface temperature retrieval in polar regions.




## File Descriptions

- **`diff_method_simulation_coef_data/`**: This folder contains simulation coefficient data specific to the four inversion methods used in the algorithm. These coefficients are essential for applying the different inversion methods accurately.

- **`Retrieve_lst_main.m`**: This is the main function that controls the entire surface temperature retrieval process. It decides which method to apply based on the user input and geographical region. It integrates all the other functions and provides the final output.

- **`fun_readxml_meta.m`**: A helper function used to read metadata from the input XML files, ensuring that all relevant satellite data and parameters are correctly parsed and utilized.

- **`radiance2BT.m`**: This function is responsible for converting the radiance data from the SDGSAT-1 satellite into brightness temperature, which is required for the temperature retrieval process.

- **`user_input_emi.m`**: This function allows users to input custom emissivity maps if needed. If no custom map is provided, the algorithm can automatically handle the default emissivity values.

## Running the Algorithm

## Running the Algorithm

1. Open the MATLAB environment (MATLAB 2023 or later).
2. Load the `Retrieve_lst_main.m` script and run it.
3. Follow the instructions in the script to input parameters:
   - If you're using custom emissivity maps, set `input_emi_flag` to `'yes'` and specify the path to the SDGSAT-1 multispectral data, as the system will automatically calculate the emissivity map.
   - If not, set `input_emi_flag` to `'no'`, and the algorithm will automatically choose the inversion method based on the region (land or sea ice). You will need to provide the input location or region for the algorithm to process.
4. The algorithm will output the surface temperature data based on the selected inversion method.



## References

1. Dozier, J., & Warren, S. G. (1984). Land surface temperature measurements from the split window channels of the NOAA 7 Advanced Very High Resolution Radiometer. *Journal of Geophysical Research: Atmospheres*, 89(D4), 5098-5104. [DOI: 10.1029/JD089iD04p05098](https://doi.org/10.1029/JD089iD04p05098).

2. Sobrino, J. A., & Raissouni, N. (1991). Atmospheric and emissivity correction of land surface temperature measured from satellite using ground measurements or satellite data. *International Journal of Remote Sensing*, 12(4), 625-633. [DOI: 10.1080/01431169108953749](https://doi.org/10.1080/01431169108953749).

3. Ueno, T., & Lutz, R. A. (1994). A split window algorithm for estimating land surface temperature from satellites. *Remote Sensing of Environment*, 48(2), 160-170. [DOI: 10.1016/0034-4257(94)90037-9](https://doi.org/10.1016/0034-4257(94)90037-9).

4. Li, J., & Zeng, Z. (2019). Enterprise LST algorithm development and its evaluation with NOAA 20 data. *Remote Sensing of Environment*, 228, 123-136. [DOI: 10.1016/j.rse.2019.03.013](https://doi.org/10.1016/j.rse.2019.03.013).


## Contact Me

If you have any questions, issues, or suggestions regarding this project, feel free to reach out. You can contact me through the following methods:

- **Email**: [max1995@stumail.nwu.edu.cn](mailto:max1995@stumail.nwu.edu.cn)
- **GitHub Issues**: For project-related inquiries, please open an issue in the repository.

I welcome contributions, bug reports, and feedback!
