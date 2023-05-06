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


% Podjela podataka u satnu razinu
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

%TRENIRANJE MODELA
% BIC
% EVALUACIJA
results = []; 
prediction = [];
test = [];
for i=7:18
    data = eval(sprintf('hour_data_%d', i));
    train_data = data.Active_Power(1:end-1);
    test_data = data.Active_Power(end);
    LOGL = zeros(4,4,2);
    PQ = zeros(4,4,2);
    P = []; Q=[]; D=[];
    for p=1:4
        for d=1:2
            for q=1:4
                try
                    mod=arima(p,d,q);
                    [fit,~,LOGL(p,q,d)]=estimate(mod,train_data);
                catch ME
                    P=[P p] ;Q =[Q q]; D=[D d];
                end
                PQ(p,q,d) = p+q+d;
            end
        end
    end

    for i=1:numel(P)
        LOGL(P(i),Q(i),D(i)) = Inf;
    end

    LOGL = reshape(LOGL,p*q*d,1);
    PQ = reshape(PQ,p*q*d,1);
    [~,bic]=aicbic(LOGL,PQ+1,numel(train_data'));
    R=reshape(bic,p,q,d);
    R(R==-Inf)=Inf;
    [mini,ind]=min(R(:));
    [p,q,d]=ind2sub(size(R),ind);
    results=[results;p,d,q];
    mdl=estimate(arima(p,d,q),train_data);
    forecast_value= forecast(mdl,1,'Y0',train_data);
    prediction = [prediction; forecast_value];
    test = [test;test_data];
end



new_prediction = zeros(24,1);
new_prediction(7:18) = prediction;
new_test = zeros(24,1);
new_test(7:18) = test;
t=0:23;
t=t';
plot(t,new_prediction,LineStyle="--",LineWidth=2,DisplayName='Predviđena vrijednost')
hold on;
plot(t,new_test,LineWidth=2,DisplayName='Stvarna vrijednost')


%EVALUACIJA MODELA

mae = mean(abs(new_prediction - new_test));
rmse = sqrt(mean((new_prediction - new_test).^2));
