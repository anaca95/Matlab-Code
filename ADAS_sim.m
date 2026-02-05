%% Load ADAS data

t1 = readtable("ADAS_EV_Dataset.csv");
%% Separate events

[counts, events] = groupcounts(t1.ADAS_output);
rows_acc = t1.ADAS_output == "Accelerate";
rows_brk = t1.ADAS_output == "Brake";
rows_lane_corr = t1.ADAS_output == "Lane Correct";
rows_keep_speed = t1.ADAS_output == "Maintain Speed";


acc = t1(rows_acc,:);
brk = t1(rows_brk,:);
lane_corr = t1(rows_lane_corr,:);
keep_speed = t1(rows_keep_speed,:);



%% Find thresholds
% acc
min_acc = min(acc.acceleration_mps2);
max_acc = mean(acc.acceleration_mps2);
% brk
min_brk_intensity = min(brk.brake_intensity);
max_brk_intensity = max(brk.brake_intensity);
min_regen_braking_usage = min(brk.regen_braking_usage);
max_regen_braking_usage = max(brk.regen_braking_usage);
% lane dev
min_lane_deviation = min(lane_corr.lane_deviation);
max_lane_deviation = max(lane_corr.lane_deviation);
min_steering_angle = min(lane_corr.steering_angle);
max_steering_angle = max(lane_corr.steering_angle);

%% Design curves

t = 0:0.001:10000;   % time vector
% create timeseries
time_length = zeros(size(t, 2), 1);


a = zeros(size(t));

idx1 = t >= 0 & t < 500;
a(idx1) = 0.5 * abs(sin(pi*(t(idx1))/10));

idx2 = t >= 500 & t <= 1000;
a(idx2) = 3 * abs(sin(pi*(t(idx2)-10)/10));

idx3 = t > 1000 & t <= 1500;
a(idx3) = -2.5 * abs(sin(pi*(t(idx3)-10)/10));

idx4 = t > 1500 & t <= 2000;
a(idx4) = 0;

time_acc = timeseries(a, t);


% brake
b = zeros(size(t));

idx1b = t >= 0 & t <= 1500;
b(idx1b) = 0;

idx2b = t > 1500 & t <= 2500;
b(idx2b) = 1.5 * abs(sin(pi*(t(idx2b)-10)/10));

idx3b = t > 2500 & t <= 3500;
b(idx3b) = 0.5 * abs(sin(pi*(t(idx3b)-10)/10));

time_brk = timeseries(b, t);


