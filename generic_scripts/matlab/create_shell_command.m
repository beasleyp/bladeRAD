function [command] = create_shell_command(test_id, cap_samps, pulses, tx_gain, rx_gain, center_freq, bw, SDR_No, trigger,clock,tx_rx)
%create_shell_command - Used to create commands to run shell scripts for
%each SDR.

sdr_serial = select_SDR(SDR_No); % find SDR serial number

command = "/home/piers/repos/bladeRAD/generic_scripts/bladeRAD_shell_script.sh " + test_id + " " + cap_samps + " " + pulses + " " + tx_gain + " " + rx_gain + " " + center_freq + " " + bw + " " + sdr_serial + " " + trigger + " " + clock + " " + tx_rx; 

end