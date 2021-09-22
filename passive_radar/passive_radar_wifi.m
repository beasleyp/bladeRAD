clear all
addpath('/home/piers/repos/bladeRAD/generic_scripts/matlab',...
        '/home/piers/repos/bladeRAD/generic_scripts',...
        '/home/piers/repos/bladeRAD/generic_scripts/ref_signals/') % path to generic functions

%% Parameters - Configurable by User

% Capture parameters 
Experiment_ID = 6;       % Expeiment Name
capture_duration = 1;    % capture duration
Bw = 20e6;               % Sample Rate of SDR per I & Q (in reality Fs is double this)
save_directory = "/home/piers/Documents/Captures/"; % each experiment will save as a new folder in this directory

% Radar Parameters 
Fc = 500e6;   % Central RF    
Ref_gain = 36;
Sur_gain = 60;
Pass_SDR = 3;   % SDR to use for Passive Radar - labelled on RFIC Cover and bladeRAD Facia Panel

% Parameters not configurable by user 
    C = physconst('LightSpeed');
    Fs = Bw;
    sample_duration = 1/Fs;
    number_cap_samps = 2*(capture_duration/sample_duration)
    RF_freq = Fc/1e6;   % RF in MHz 
    Bw_M = Bw/1e6;      % BW in MHz
    file_size_MBytes = (number_cap_samps * 16)*2/(8*1e6) 

    
%% Setup Radar
    % 1 'set clock_sel external'; 2 'set clock_out enable; 3 'set clock_ref enable'

    % Setup Passive SDR 
    passive_command = create_shell_command(Experiment_ID,...
                                   number_cap_samps,... 
                                   0,...
                                   0,...
                                   Ref_gain,...
                                   Sur_gain,...
                                   RF_freq,...
                                   Bw_M,...
                                   Pass_SDR,...
                                   'master',...
                                   2,...
                                   'pass');
    %passive_command = tx_command + "&"; % uncomment for non-blocking system command execution                    
    status = system(passive_command);

%% Save Raw Data and create header file for directory 
    exp_dir = save_directory + Experiment_ID + '/';
    make_dir = 'mkdir ' + exp_dir;
    system(make_dir); % Blocking system command execution
    move_file = 'mv /tmp/passive_' + string(Experiment_ID) + '.sc16q11 ' + exp_dir;
    rtn = system(move_file);
    if rtn == 0
        "Rx Data Copyied to Save directory"
    else 
        "Rx Copy Failed"
        return
    end
    save(exp_dir + 'Passive Experimental Configuration') 


%% Load Data 
    file_location = exp_dir + 'passive_' + Experiment_ID;
    [ref_channel, sur_channel]  = load_passive_data(file_location);
    % Plot time domain signals
         figure
         plot(real(ref_channel))
         title("Ref channel time series");
         figure
         plot(real(sur_channel))
         title("Sur channel time series");


% %% Reshape capture into segments
%     %Details: segement size determines the limmit of non-ambigious Doppler
%     %shift. Comparable to the PRF in active radar. 
%     %Non-ambigous Doppler shift = seg_s/2 (Hz)
%         seg_s = 5000;           % number of segments a second. 
%         seg_size = Fs/seg_s;    % number of samples per segement
%         seg_ref_channel = reshape(ref_channel,[seg_size, (size(ref_channel,1)/seg_size)]);
%     %seg_sur_channel = reshape(sur_channel,[seg_size, (size(sur_channel,1)/seg_size)]);
%         seg_sur_channel = reshape(sur_channel,[seg_size, (size(sur_channel,1)/seg_size)]);
%     % plot spectrum of segment of ref and sur channel
%         figure
%         plot(fftshift(10*log10(abs(fft(seg_ref_channel(:,2000))))))
%         hold on 
%         plot(fftshift(10*log10(abs(fft(seg_sur_channel(:,2000))))))
% 
%  %% Decimate segments in to smaller portions
%         seg_percent = 20;           % percentage of segment used for cross coreclation of survallance and reference
%         cc_size = seg_size*10/100;  
%         dec_ref_channel = seg_ref_channel(1:cc_size,:);
%         dec_sur_channel = seg_sur_channel(1:cc_size,:);
% 
%  %% DSI Cancellation      
% %      % The required time domain filter parameters for each filter are passed 
% %      % through the kwargs interface class
% %         tdfp = kwargs;
% %         tdfp.K = 10;          % multipath echoes are backscattered from the first K range bins
% %         tdfp.D = 512;     % Maximum Doppler extension measured in Doppler bins
% % %         tdfp.T      % Number of batches for ECA-B or batch length for block LMS
% % %         tdfp.Na     % Sliding window size, measured in samples
% % %         tdfp.imp    % Implementation type
% % %         tdfp.mu     % Step size parameter for the iterative algorithms - LMS or NLMS
% % %         tdfp.lamb   % Forgetting factor for the RLS algoritm
% % %         tdfp.ui     % Update interval for the iterative algorithms - LMS, NLMS, RLS
% % %         tdfp.w_init % Initialization vector for the iterative algorithms - LMS, NLMS, RLS, (default: None)
% % 
% %         filtered_surv_ch = complex(zeros(size(dec_ref_channel)));
% %         for i=1:size(seg_ref_channel,2)
% %         filtered_surv_ch(:,i) = time_domain_filter_surveillance(dec_ref_channel(:,i), dec_sur_channel(:,i), "ECA", tdfp);
% %         end
% %         toc       
% %  
% %         
%         
% %% Window Sur channel
%         for i=1:size(seg_ref_channel,2)
%         dec_sur_channel(:,i) = windowing(dec_sur_channel(:,i), "Blackman-Harris");
%         end
%         toc
% %% Cross-Correlate segments of ref and sur
%         cc_matrix = complex(zeros((2*r_max)+1, (size(ref_channel,1)/seg_size)));
%     % range limited Xcorr
%         tic
%         for i=1:size(seg_ref_channel,2)
%         cc_matrix(:,i) = xcorr(dec_sur_channel(:,i),dec_ref_channel(:,i),r_max); %xcorr(sur_chan,ref_chan) in order to get posative r_bins
%         end
%         toc
%         cc_matrix = cc_matrix(r_max+1:end,:); %take zero shifted to +r_max shifted range bins
% 
% 
% %% RTI Plot
%     RTI_plot= transpose(10*log10(abs(cc_matrix./max(cc_matrix(:)))));
% 
%     Range_bin = linspace(0,r_max,size(cc_matrix,1));
%     time_axis = linspace(0,Cap_dur,size(cc_matrix,2));
% 
%     figure
%     fig = imagesc(Range_bin,time_axis,RTI_plot,[-50,0]);
%     % xlim([1 20])
%     %ylim([0 0.0005])
%     grid on            
%     colorbar
%     ylabel('Time (Sec)')
%     xlabel('Range Bin')   
%     fig_title = "Psudo Range Shifted";
%     title(fig_title);
%     fig_name = save_directory + "/RTI_" + Test_id + ".jpg";
%     saveas(fig,fig_name,'jpeg')
%     plot_signal = toc
%     % 
% 
% %% CAF of entire capture
%     f_axis = linspace(-seg_s/2,seg_s/2,size(cc_matrix,2));
%     t_cc_matrix = transpose(cc_matrix);
%     CAF = fftshift(fft(t_cc_matrix,size(t_cc_matrix,1),1),1);
%     figure
%     imagesc(Range_bin,f_axis,10*log10(abs(CAF./max(CAF(:)))),[-50 1]); 
%     ylim([-500 500])     
%     % xlim([1 20])
%     colorbar
%      ylabel('Doppler Shift (Hz)')
%      xlabel('Range Bin')   
%      fig_title = "Psudo Range % Doppler Shifted";
%  
% 
% %% Spectrogram 
%     r_bin = 1;
%     l_fft = 1024;
%     pad_factor = 1;
%     overlap_factor = 0.99;
%     [spect,f] = spectrogram(cc_matrix(r_bin,:),l_fft,round(l_fft*overlap_factor),l_fft*pad_factor,seg_s,'centered','yaxis');
%     % spect(pad_factor*l_fft/2-1:pad_factor*l_fft/2+1,:) = 0;
%     v=dop2speed(f,C/Fc)*2.237;
%     spect= 10*log10(abs(spect./max(spect(:))));
%     figure
%     fig = imagesc(time_axis,f,spect,[-50 0]);   
%     ylim([-600 600])
%     colorbar
%     xlabel('Time (Sec)')
%     % ylabel('Radial Velocity (mph)')   
%     ylabel('Doppler Frequency (Hz)')  
%     fig_title = "Spectrogram - R Bin: " + r_bin + " - Test id: " + Test_id;
%     title(fig_title);
%     fig_name = save_directory + "/Spectrogram_" + Test_id + ".jpg";
%     saveas(fig,fig_name,'jpeg')
%     % 
% 
% % %% MTI Filtering 
% % % Single Delay Line Filter 
% % MTI_Data = zeros(size(cc_matrix));
% %       for i=2:size(cc_matrix,2)
% %             MTI_Data(:,i) = cc_matrix(:,i)-cc_matrix(:,i-1);
% %       end
% %       
% % % %Plot MTI RTI      
% % % MTI_RTI_plot= transpose(10*log10(abs(MTI_Data./max(MTI_Data(:)))));
% % % figure
% % % fig = imagesc(Range_bin,time_axis,MTI_RTI_plot,[-50,0]);
% % % xlim([1 20])
% % % %ylim([0 0.0005])
% % % grid on            
% % % colorbar
% % % ylabel('Time (Sec)')
% % % xlabel('Range Bin')   
% % % fig_title = "Monostatic Single Delay Line MTI  RTI - Test " + Test_id;
% % % title(fig_title);
% % % fig_name = save_directory + "/MTI_RTI_" + Test_id + ".jpg";
% % % saveas(fig,fig_name,'jpeg')
% % % plot_signal = toc     
% % 
% % % 
% % % %Plot MTI Spectrogram  
% % [spect,f] = spectrogram(MTI_Data(r_bin,:),l_fft,round(l_fft*overlap_factor),l_fft*pad_factor,seg_s,'centered','yaxis');
% % % spect(pad_factor*l_fft/2-1:pad_factor*l_fft/2+1,:) = 0;
% % v=dop2speed(f,C/Fc)*2.237;
% % spect= 10*log10(abs(spect./max(spect(:))));
% % figure
% % fig = imagesc(time_axis,f,spect,[-30 0]);
% % ylim([-600 600])
% % colorbar
% % xlabel('Time (Sec)')
% % % ylabel('Radial Velocity (mph)')   
% % ylabel('Doppler Frequency (Hz)')  
% % fig_title = "Monostatic Single Delay Line MTI Spectrogram - Test " + Test_id;
% % title(fig_title);
% % fig_name = save_directory + "/MTI_Spectrogram_" + Test_id + ".jpg";
% % saveas(fig,fig_name,'jpeg')
% % 
