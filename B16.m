% WCC 5-28-2021
% Q: how to read Andrea's .b16 files captured by PCO high-speed camera
% A: follow document "A1 Image File Formats"
% WCC 5-28-2021: add image dimensions

classdef B16 < handle
    
    properties
        d
        dd
        im
        im_width 
        im_height
        header_length
        file_size
    end
    
    methods
        
        function obj = B16 (fn)
            
            % example: my_b16_obj = B16('Raw_Fmount_036Hz_27698us_min0_max2836_colTemp3150_tint.16_000597.b16')
            
            % remember to enter the data filename; or put the filename here
            % fn = 'test.b16';
            
            % read the whole file
            fi = fopen(fn,'r');
            obj.d = fread(fi);
            fclose(fi);
            
            % process it in bytes
            obj.dd = uint8(obj.d);
            
            obj.list_header;
            
            obj.reconstruct;
            
            obj.save_image;
            
        end
        
        function save_image (obj)
            % the image is just for visualization; use the original data
            imwrite(obj.im/256/256,'test.tif')
        end
        
        function visualize_data (obj)
            % show the image for debugging purposes
            imagesc(obj.im);
            axis image
        end
        
        
        function reconstruct (obj)
            % check data length
            assert(obj.im_width*obj.im_height*2 == obj.file_size - obj.header_length)
            
            % convert 16-bit pixel data from bitmap to 2D structure
            pixeldata_start_from = obj.header_length + 1
            
            % crop the bitmapped pixel data
            ddd = obj.dd(pixeldata_start_from:end);            
            
            % chop it into two-byte * height * width
            im2 = reshape(ddd,2,obj.im_height,obj.im_width); 
            
            % 
            % convert the two-byte as "16-bit unsigned integer"
            % 
            im3 = double(im2(1,:,:)) + 256*double(im2(2,:,:));

            % reduce dimensionality to 2
            im4 = squeeze(im3);
            
            % store it
            obj.im = im4;
            
            % 
            % TO VERIFY: the data range does not match the header info --
            % b/w min and b/w max
            % 
            datalin = im4(:);
            max(datalin);
            min(datalin);
        end
        
        function list_header (obj)
            % list the header
            % #3 is the header length
            for i = 1:17
                value = obj.get_i_word(i);
                fprintf('%d: %d\n',i,value)
            end
            
            obj.im_width = obj.get_i_word(4);
            obj.im_height = obj.get_i_word(5);
            obj.file_size = obj.get_i_word(2);
            obj.header_length = obj.get_i_word(3);
        end
        
        function wd = byte2word (obj,b)
            % convert 4 bytes into a 32-bit word
            % little endien
            w0 = uint32(b(1));
            w1 = uint32(b(2));
            w2 = uint32(b(3));
            w3 = uint32(b(4));
            
            % I know this line looks very dumb
            wd = w0 + w1*256 + w2*256*256 + w3*256*256*256;
        end        
        
        function value = get_i_word(obj,i)
            % retrieve the value from a field in the header
            idx = (i-1)*4+1;
            byte4 = obj.dd(idx:idx+3);
            value = obj.byte2word(byte4);
        end
        
    end
    
end