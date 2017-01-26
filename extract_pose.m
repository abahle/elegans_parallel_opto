% extract_pose is a script which takes in a an images of a single worm and
% processes it to obtain: the worm centerline, outline and the intensities
% along the center line. It also contains lots of other information which
% can be used flexibly
%
% Usage
% image_data = extract_pose('/Users/andrewbahle/Dropbox/PHD/Flavell Rotation/Projects/Tracking/crapJPEGs'...
% 'jpeg','/Users/andrewbahle/Dropbox/PHD/Flavell Rotation/Projects/Tracking/test3');
%
% -------------------------------------------------------------------------
% INPUT
% filein:   a path to a file containing your image files
%
% <options> 
% type: this is a string specifying the file type that you have saved your
% images - default is 'jpg'
% 
% fileout:  a path to a file where you would like to save your output if
% this is specified then the output will be plotted and saved as an output
% 
% OUTPUT
% 
% map:  map is a struct that contains the positions of the aligned worm
% center and outline as well as the profile values of the center of the
% worm and the angles between each segment of a fitted spline

function map = extract_pose(filein,varargin)
    time = cputime;
    % check for optional inputs
    if length(varargin) > 3
        error('this function only allows up to 3 optional inputs');
    end
    
    % set defaults of roptional inputs
    opt_args = {'jpeg',[]};
    
    % overwrite defaults with varargin if they exist
    opt_args(1:length(varargin)) = varargin;   
    [type, fileout] = opt_args{:};
    
    % get the names of all files of the specified type in the input folder 'filepath'
    filepath = sprintf('%s/*.%s',filein,type);
    names = dir(filepath);
    names = {names.name};
    map = cell(1,length(names));
    
    for ii = 1:50%length(names)
     %% Process the image and get releavant properties           
        status = false;   
        fprintf('processing image #%i\n',ii)
        fnum = randi(length(names),1);
        Ori = im2double(imread(names{fnum}));
        %fnum = ii;
        %Ori = im2double(imread(names{fnum})); % save the original image
        IM = (Ori);
        
        thresh = 3*sqrt(var(IM(:))); %calculate the threshold
        IM = analysis.process(IM,thresh,15,1); % process
        
        [boxes,~] = analysis.imOrientedBox(IM);
        theta = -deg2rad(boxes(5));
        
        boundary = bwperim(IM); % get boundary
        center = bwmorph(IM,'thin',Inf); % get center line
            
%         [b,a] = find(center == 1);
%         r = analysis.total_ls(a,b); % fit with total least squares     
%         theta = 2*pi-atan(-r);  % get the optimal angle to rotate               
        map{ii} = analysis.align(theta,boundary,center); % align
        
%         r2 = analysis.regular_ls(map{ii}.center(1,:),map{ii}.center(2,:)); 
%         yp = map{ii}.center(1,:)*r2;
%         figure, plot(x,y,'k.', ...
%          map{ii}.center(1,:),map{ii}.center(2,:),'r.', ...
%             map{ii}.center(1,:),yp,'-b')
        
        map{ii}.cProfile = Ori.*center; % get the profile of the worm center


    %% Fit interpolating spline to rotated center line and get angles
    try
       N = 101;
       xx = linspace(min(map{ii}.center(1,:)),max(map{ii}.center(1,:)),N);
       yy = spline(map{ii}.center(1,:),map{ii}.center(2,:),xx);        
       map{ii}.angles = analysis.get_angles(xx,yy,N);
       status = true;
    catch
        fprintf('could not fit spline to file # %i',fnum)
    end
%% plot          
        if ~isempty(fileout)   
            h = figure; set(h, 'Visible', 'off'); hold on
                subplot(3,2,1:2:3), axis equal
                    imagesc(Ori) % plot original image
%                 subplot(3,2,2), axis square
%                     imagesc(IM) % plot binary image
                subplot(3,2,2:2:4)
                    plot(map{ii}.boundary(2,:),map{ii}.boundary(1,:),'k.'), hold on % plot boundary 
                    plot(map{ii}.center(2,:),map{ii}.center(1,:),'r.'), axis equal % plot center
                    %plot(xx,yy,'bo'), axis equal
                
                if status
                    subplot(3,2,5:6)
                    plot(1:N-1,map{ii}.angles), title('angles of the worm pose') % plot angles
                end
                %subplot(4,2,7:8)
    %             
    %             imagesc(cProfile)
    %             
                         
            saveas(gca, fullfile(fileout, sprintf('%i',fnum)),'jpeg');            
        end % end of plotting function
    end % end of image file loop
    
    fprintf('time elapsed = %6.2f\n',cputime-time)
end % end of function