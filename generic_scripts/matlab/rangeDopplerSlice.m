function [number_cpi,pulses_per_cpi,range_doppler_slices] = rangeDopplerSlice(radar_matrix,cpi,PRF,cpi_overlap,zero_padding,window_type)
%RANGEDOPPLERSLICE Summary of this function goes here
%   Detailed explanation goes here
  % loop through matrix and create array of range-Doppler slices      
  
  pulses_per_cpi = ceil(PRF*cpi); % number of pulses per CPI
  cpi_stride = round(pulses_per_cpi*(1-cpi_overlap)); % number of pulses to stride each for next CPI
  number_cpi = round(size(radar_matrix,2)/cpi_stride);
  doppler_bins = (pulses_per_cpi*zero_padding);
  if mod(doppler_bins,2) == 0
      doppler_bins = doppler_bins + 1;
  end
  
  % normalised cpi 
            norm_range_doppler_slices = createArrays(number_cpi, [size(radar_matrix,1) doppler_bins]);
          % normalised cpi slices on dB scale
          
            for i=1:number_cpi-1
                 i
                 % window section of pulses from raw data
                 cpi_window = radar_matrix(:,i*cpi_stride:(i+1)*cpi_stride);
                 % window data to reduce sidelobes
                 w = transpose(window(window_type,size(cpi_window,2)));
                 cpi_window = cpi_window .* w;
                 % fft cpi window to get CAF slice
                 caf = fftshift(fft(cpi_window,doppler_bins,2),2);
                 % normalise cpi slice to 0
                 range_doppler_slices{i} = transpose(caf);
                 % convert to dB power scale
            end
end

