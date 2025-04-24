# SDGSAT-1 Polar Ice and Snow Surface Temperature Retrieval Algorithm

This repository contains an algorithm for retrieving the surface temperature of polar ice and snow based on SDGSAT-1 satellite data. The algorithm leverages four window-based methods for inversion, which include:

- **PR1984**: Method developed by Priestley & Robinson (1984)
- **VI1991**: Method developed by Vidale & Inoue (1991)
- **UL1994**: Method developed by Ueno & Lutz (1994)
- **Enter2019**: Method developed by Enter et al. (2019)

These methods are commonly used in remote sensing for surface temperature retrieval in polar regions.




## File Descriptions

- **`diff_method_simulation_coef_data/`**: This folder contains simulation coefficient data specific to the four inversion methods used in the algorithm. These coefficients are essential for applying the different inversion methods accurately.

- **`Retrieve_lst_main.m`**: This is the main function that controls the entire surface temperature retrieval process. It decides which method to apply based on the user input and geographical region. It integrates all the other functions and provides the final output.

- **`fun_readxml_meta.m`**: A helper function used to read metadata from the input XML files, ensuring that all relevant satellite data and parameters are correctly parsed and utilized.

- **`radiance2BT.m`**: This function is responsible for converting the radiance data from the SDGSAT-1 satellite into brightness temperature, which is required for the temperature retrieval process.

- **`user_input_emi.m`**: This function allows users to input custom emissivity maps if needed. If no custom map is provided, the algorithm can automatically handle the default emissivity values.

## Running the Algorithm

1. Open the MATLAB environment.
2. Load the `Retrieve_lst_main.m` script and run it.
3. Follow the prompts in the console to input parameters:
   - If you're using custom emissivity maps, set `input_emi_flag` to `'yes'` and specify the path to the emissivity map.
   - If not, set `input_emi_flag` to `'no'`, and the algorithm will automatically choose the inversion method based on the region (land or sea ice).
4. The algorithm will output the surface temperature data based on the selected inversion method.

## Contact Me

If you have any questions, issues, or suggestions regarding this project, feel free to reach out. You can contact me through the following methods:

- **Email**: [max1995@stumail.nwu.edu.cn](mailto:max1995@stumail.nwu.edu.cn)
- **GitHub Issues**: For project-related inquiries, please open an issue in the repository.

I welcome contributions, bug reports, and feedback!
