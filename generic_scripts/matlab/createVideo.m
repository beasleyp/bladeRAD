function createVideo(frame_array,frame_rate, x_axis, x_limit, y_axis, y_limit, dynamic_range, file_name, video_title)
%CREATE_VIDEO Summary of this function goes here
%   Detailed explanation goes here
% create the video writer
     writerObj = VideoWriter(file_name);
     writerObj.FrameRate = frame_rate;           
     open(writerObj)   
     
     for i=1:size(frame_array,2)-1   

        frame =  10*log(abs(frame_array{i}./max(frame_array{i}(:))));
%         frame =  (abs(frame_array{i}./max(frame_array{i}(:))));


        fig =  transpose(imagesc(x_axis,y_axis, frame, [-dynamic_range 0]));
        title(video_title + ' - CPI no.: ' + i)
        ylabel('Doppler (Hz)')
        xlabel('Range (m)')   
        c = colorbar;
        c.Label.String='Norm Power (dB)';
        ylim([-y_limit y_limit]);
        xlim([-inf x_limit]);
        colormap jet;
        saveas(fig,'frame','png');
        im = imread('frame.png');
        writeVideo(writerObj, im);
     end
 
 close(writerObj);

end