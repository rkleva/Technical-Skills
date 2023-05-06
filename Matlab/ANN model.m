clc
clear
clear all

%PRIPREMA PODATAKA

%Učitaj .csv file
data = readtable("5-Site_1_11-2018_08-2020.csv");

%Makni drugi stupac
data(:,2) = [];
data(:,2) = [];

%Rješi se svih vrijednosti gdje nema snage iz PV-a
%
% Pretvori timestamp stupac u datetime objekt
data.Timestamp = datetime(data.Timestamp, 'InputFormat', 'dd/MM/yyyy HH:mm:ss');

%Stupci koje ćemo zadržati
keep_rows = (hour(data.Timestamp) >= 7) & (hour(data.Timestamp) <= 18);
keep_rows = keep_rows & (data.Active_Power >= 0);
data = data(keep_rows, :);

%Interpoliraj vrijednosti koje nedostaju
data.Active_Power(data.Active_Power == 0) = NaN;
nan_indices = find(isnan(data.Active_Power));

data_interp = interp1(find(~isnan(data.Active_Power)), data.Active_Power(~isnan(data.Active_Power)),nan_indices, 'linear'); 
data.Active_Power(isnan(data.Active_Power)) = data_interp;

%Podatci s kojima radimo
plot(data.Timestamp, data.Active_Power);


hour_of_day = hour(data.Timestamp);

hour_data_7 = data(hour_of_day == 7, :);
hour_data_8 = data(hour_of_day == 8, :);
hour_data_9 = data(hour_of_day == 9, :);
hour_data_10 = data(hour_of_day == 10, :);
hour_data_11 = data(hour_of_day == 11, :);
hour_data_12 = data(hour_of_day == 12, :);
hour_data_13 = data(hour_of_day == 13, :);
hour_data_14 = data(hour_of_day == 14, :);
hour_data_15 = data(hour_of_day == 15, :);
hour_data_16 = data(hour_of_day == 16, :);
hour_data_17 = data(hour_of_day == 17, :);
hour_data_18 = data(hour_of_day == 18, :);
new=[];
old=[];
mse=[];
for c=7:18
    data = eval(sprintf('hour_data_%d', c));
    
    num_days = length(data.Active_Power);
    train_size = num_days -1;
    X_train = data.Active_Power(1:train_size-1)';
    Y_train = data.Active_Power(2:train_size)';
    X_test = data.Active_Power(train_size:num_days-1)';
    Y_test = data.Active_Power(train_size+1:num_days)';
 
    % Train ANN
    hidden_layer_size = 10; % number of hidden nodes
    net = feedforwardnet(hidden_layer_size); % create ANN
    net.trainFcn = 'trainlm'; % use Levenberg-Marquardt backpropagation
    net = train(net, X_train, Y_train); % train ANN
    
    % Test ANN
    Y_pred = net(X_test); % predict PV power for test data
    mse1 = mean((Y_pred - Y_test).^2); % calculate mean squared error
    mse=[mse;mse1];
    new=[new;Y_pred];
    old=[old;Y_test];
    
end
new_pred = zeros(24,1);
new_pred(7:18) = new;
new_test = zeros(24,1);
new_test(7:18) = old;
t=0:23;
t=t';
plot(t,new_pred,LineStyle="--",LineWidth=2,DisplayName='Predviđena vrijednost')
hold on;
plot(t,new_test,LineWidth=2,DisplayName='Stvarna vrijednost')

%EVALUACIJA MODELA

mae = mean(abs(new_pred - new_test));
rmse = sqrt(mean((new_pred - new_test).^2));
