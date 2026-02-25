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
keep_speed = t1(rows_keep_speed,2);



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


%%
speed = t1.speed_kmh;
acc_status = zeros(size(t1, 1), 1);
for i = 1 : size(t1, 1)
    if i == 1 && t1.ADAS_output(i) == "Accelerate"
        acc_status(i) = 1;
    elseif i == 1 && t1.ADAS_output(i) ~= "Accelerate"
        acc_status(i) = 1;
    elseif t1.speed_kmh(i) > t1.speed_kmh(i-1)
        acc_status(i) = acc_status(i-1) + 1;
    end
    
end


% brake
brk_status = zeros(size(t1, 1), 1);
for i = 1 : size(t1, 1)
    if i == 1 && t1.ADAS_output(i) == "Brake"
        brk_status(i) = 1;
    elseif i == 1 && t1.ADAS_output(i) ~= "Brake"
        brk_status(i) = 0;
    elseif t1.speed_kmh(i) < t1.speed_kmh(i-1)
        brk_status(i) = brk_status(i-1) + 1;
    
    end
end
%% Add columns to the table
t1.("acc_status") = acc_status;
t1.("brk_status") = brk_status;
%% Plot the impact of accelerating and braking Vs. speed
tiledlayout(2, 1)
nexttile
scatter(acc_status,speed, 10,'magenta');
xlabel("Acceleration Status");
ylabel("Speed")
title("Speed behavior after accelerating")
grid on
nexttile
scatter(brk_status, speed, 10, 'red');
xlabel("Brake Status");
ylabel("Speed")
title("Speed behavior after braking")
grid on

%% Generate synthetic samples

for i = 1: length(t1.speed_kmh)
    idx(i) = i;
end


% Speed
lower_lim = min(t1.speed_kmh);
higher_lim = max(t1.speed_kmh);
pd = fitdist(t1.speed_kmh,'Normal');    % estimate parameters
synthetic_speed = random(pd,10000,1);
synthetic_speed = synthetic_speed(synthetic_speed >= lower_lim & synthetic_speed <= higher_lim);
figure
histogram(t1.speed_kmh)
hold on
histogram(synthetic_speed)
hold off
legend(["Original Speed", "Synthetic"])


% Battery level
lower_lim = min(t1.battery_level);
higher_lim = max(t1.battery_level);
pd = fitdist(t1.battery_level,'Normal');    % estimate parameters
synthetic_bat = random(pd,10000,1);
synthetic_bat = synthetic_bat(synthetic_bat >= lower_lim & synthetic_bat <= higher_lim);
figure
histogram(t1.battery_level)
hold on
histogram(synthetic_bat)
hold off
legend(["Original battery level", "Synthetic"])


% Energy consumption
lower_lim = min(t1.energy_consumption);
higher_lim = max(t1.energy_consumption);
pd = fitdist(t1.energy_consumption,'Normal');    % estimate parameters
synthetic_ener = random(pd,10000,1);
synthetic_ener = synthetic_ener(synthetic_ener >= lower_lim & synthetic_ener <= higher_lim);
figure
histogram(t1.energy_consumption)
hold on
histogram(synthetic_ener)
hold off
legend(["Original energy consumption", "Synthetic"])


% Regen braking usage
lower_lim = min(t1.regen_braking_usage);
higher_lim = max(t1.regen_braking_usage);
pd = fitdist(t1.regen_braking_usage,'Normal');    % estimate parameters
synthetic_rbk = random(pd,10000,1);
synthetic_rbk = synthetic_rbk(synthetic_rbk >= lower_lim & synthetic_rbk <= higher_lim);
figure
histogram(t1.regen_braking_usage)
hold on
histogram(synthetic_rbk)
hold off
legend(["Original regenative brake", "Synthetic"])

% Lane deviation
lower_lim = min(t1.lane_deviation);
higher_lim = max(t1.lane_deviation);
pd = fitdist(t1.lane_deviation,'Normal');
synthetic_lkp = random(pd,10000,1);
synthetic_lkp = synthetic_lkp(synthetic_lkp >= lower_lim & synthetic_lkp <= higher_lim);
figure
histogram(t1.lane_deviation)
hold on
histogram(synthetic_lkp)
hold off
legend(["Original lane deviation", "Synthetic"])

% Obstacle distance
lower_lim = min(t1.obstacle_distance);
higher_lim = max(t1.obstacle_distance);
pd = fitdist(t1.obstacle_distance,'Normal');
synthetic_obs = random(pd,10000,1);
synthetic_obs = synthetic_obs(synthetic_obs >= lower_lim & synthetic_obs <= higher_lim);
figure
histogram(t1.obstacle_distance)
hold on
histogram(synthetic_obs)
hold off
legend(["Original obstacle distance", "Synthetic"])

% Traffic density
lower_lim = min(t1.traffic_density);
higher_lim = max(t1.traffic_density);
pd = fitdist(t1.traffic_density,'Normal');
synthetic_trf = random(pd,10000,1);
synthetic_trf = synthetic_trf(synthetic_trf >= lower_lim & synthetic_trf <= higher_lim);
figure
histogram(t1.traffic_density)
hold on
histogram(synthetic_trf)
hold off
legend(["Original traffic density", "Synthetic"])

% Steering angle
lower_lim = min(t1.steering_angle);
higher_lim = max(t1.steering_angle);
pd = fitdist(t1.steering_angle,'Normal');
synthetic_ste = random(pd,10000,1);
synthetic_ste = synthetic_ste(synthetic_ste >= lower_lim & synthetic_ste <= higher_lim);
figure
histogram(t1.steering_angle)
hold on
histogram(synthetic_ste)
hold off
legend(["Original steering angle", "Synthetic"])


% Reaction time
lower_lim = min(t1.reaction_time);
higher_lim = max(t1.reaction_time);
pd = fitdist(t1.reaction_time,'Normal');
synthetic_rea = random(pd,10000,1);
synthetic_rea = synthetic_rea(synthetic_rea >= lower_lim & synthetic_rea <= higher_lim);
figure
histogram(t1.reaction_time)
hold on
histogram(synthetic_rea)
hold off
legend(["Original reaction time", "Synthetic"])

