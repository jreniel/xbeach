function plotdata()
%% coefficients and settings
[runid,testid,datadir]=testinfo
fid = fopen([datadir 'datanam.txt']);
Tnam = fgetl(fid);
nvar = str2num(fgetl(fid));
for i = 1:nvar
    line = fgetl(fid);
    [nam,remain] = strtok(line,' ');
    [dummy,remain] = strtok(remain,'=');
    par.(nam) = str2num(remain(2:end));
end
fclose(fid);
%% measurements
load([datadir,Tnam]);

%% simulation results
nam = [{'zb'};{'H'};{'zs'};{'hh'};{'u'};{'ue'};{'urms'};{'ccg'};{'Sug'}; {'Fx'};];

% dimensions
fid = fopen('dims.dat','r');
temp = fread(fid,[3,1],'double');
nt = temp(1);
nx = temp(2)+1;
ny = temp(3)+1;
fclose(fid);

% read grid coordinates
fid = fopen('xy.dat','r');
xw = fread(fid,[nx,ny],'double');
yw = fread(fid,[nx,ny],'double');
% x = fread(fid,[nx,ny],'double');
% y = fread(fid,[nx,ny],'double');
fclose(fid);

% read XBeach output
ts = 0:1:nt-1;
for j = 1:length(nam)
    temp = zeros(nx,ny,nt);
    fid = fopen([nam{j},'.dat'],'r');
    for i = 1:nt
        temp(:,:,i) = fread(fid,[nx,ny],'double');  % all data
    end
    fclose(fid);
    s.(nam{j}) = zeros(nx,nt);
    s.(nam{j}) = squeeze(temp(:,2,:));
end

% setup
s.setup = mean(s.zs-max(0,s.zb),2);

% long wave height
h = s.zs-s.zb;
windowSize = 60; % ten seconds window
fs = fspecial('average',windowSize);
hm = [];
for i=1:length(xw)
    hm(i,:) = imfilter(h(i,:),fs,'symmetric');
end
zs = h-hm;
% hm=mean(h,2);
% for i=1:size(h,2);
%     zs(:,i) = h(:,i)-hm;
% end

s.Hrms_lfm = sqrt(8)*std(zs')';
s.Hrms_lfm2 = sqrt(8)*std(h')';
s.Hrms_hfm = sqrt(mean(s.H.^2,2));
% s.Hrms_lfm = sqrt(8)*std(detrend((s.zs-s.zb)'))';
s.Hrms_m = sqrt(s.Hrms_hfm.^2 + s.Hrms_lfm.^2);
s.Urms_hfm = sqrt(mean(s.urms.^2,2));
s.Urms_lfm = std(s.u')';
s.Urms_m = sqrt(s.Urms_hfm.^2 + s.Urms_lfm.^2);
s.Um = mean(s.ue,2);
s.Cm = mean(s.ccg,2);
dz = s.zb(:,end)-s.zb(:,1);
Tsim = nt*par.morfac*par.tint;
s.Sdzb = (1-par.np)*flipud(cumsum(flipud(dz)))*(xw(2,2)-xw(1,2))/Tsim;
Tout = round([0 0.1 0.3 1.0 2.04 6.0]*3600/par.morfac/par.tint)+1;
s.zb_interval = s.zb(:,Tout);

% Analysis long waves
w = 2*pi/par.Tp;
hh = max(mean(h,2),0.01); % max(h,0.01);
k = disper(w,hh,par.g);
cg = w./k*0.5.*(1+2*k.*hh./sinh(2*k.*hh));
% cg = sqrt(par.g*hh);
% Guza
s.etain=zeros(nx,nt);
s.etaout=zeros(nx,nt);
s.uin=zeros(nx,nt);
for i = 1:nx
    s.etain(i,:) = (detrend(zs(i,:)).*sqrt(9.81.*hh(i,:))+detrend(s.u(i,:)).*hh(i,:))./(cg(i,:)+sqrt(9.81.*hh(i,:)));
    s.etaout(i,:) = (detrend(zs(i,:)).*sqrt(9.81.*hh(i,:))-detrend(s.u(i,:)).*hh(i,:))./(cg(i,:)+sqrt(9.81.*hh(i,:)));
    s.uin(i,:) = par.g./cg(i,:).*s.etain(i,:);
end
s.Hrms_lfm_in = sqrt(8)*std(s.etain')';
s.Hrms_lfm_out = sqrt(8)*std(s.etaout')';
% phase averaged work on long waves (Battjes, 2004)
s.R = -mean(s.uin.*s.Fx,2);
% correlation short and longh waves
s.rho = []; s.pval = [];
% for i = 1:nx
%     [s.rho(i), s.pval(i)] = corr(detrend(s.zs(i,:))',s.Hrms(i,:).^2');
% end
%% figures;
dxext = 0;
% hydrodynamics
figure(1);
subplot(221);
plot(xw,s.Hrms_m,'k-','LineWidth',1.5); hold on; plot(xhrms+dxext,Hrms,'ks','LineWidth',1.5);
plot(xw,s.Hrms_hfm,'k--','LineWidth',1.5); hold on; plot(xhrms+dxext,Hrms_hf,'k^','LineWidth',1.5);
plot(xw,s.Hrms_lfm,'k-.','LineWidth',1.5); hold on; plot(xhrms+dxext,Hrms_lf,'kv','LineWidth',1.5);
xlabel('x [m]'); ylabel('H_{rms} [m]'); axis([min(min(xw)) max(max(xw)) 0 1.25]);
subplot(222);
plot(xw,s.setup,'k-','LineWidth',1.5); hold on; plot(xsetup+dxext,setup,'ks','LineWidth',1.5);
xlabel('x [m]'); ylabel('\eta_{mean} [m]'); axis([min(min(xw)) max(max(xw)) -0.1 0.3]);
subplot(223);
plot(xw,s.Urms_m,'k-','LineWidth',1.5); hold on; plot(xurms+dxext,Urms,'ks','LineWidth',1.5);
plot(xw,s.Urms_hfm,'k--','LineWidth',1.5); hold on; plot(xurms+dxext,Urms_hf,'k^','LineWidth',1.5);
plot(xw,s.Urms_lfm,'k-.','LineWidth',1.5); hold on; plot(xurms+dxext, Urms_lf,'kv','LineWidth',1.5);
xlabel('x [m]'); ylabel('U_{rms} [m]'); axis([min(min(xw)) max(max(xw)) 0 1.0]);
subplot(224);
plot(xw,s.Um,'k-','LineWidth',1.5); hold on; plot(xum+dxext,Um,'ks','LineWidth',1.5);
xlabel('x [m]'); ylabel('U_{mean} [m]'); axis([min(min(xw)) max(max(xw)) -0.5 0.1]);
print('hydrodynamics.png','-dpng');

% wave spectra
% simulated wave spectra
for i = 1:length(xhrms)
    ind(i) = find(xw(:,2)==xhrms(i));
end
zstemp = zs(ind,:);
n = length(zstemp);
T = ts(end);
df = 1/T;
f = df*[0:1:round(n/2) -1*floor(n/2)+1:1:-1];
zsf = fft(zstemp,[],2);
varf1 = 2*T/n^2*abs(zsf).^2;
fac = 100;
df11 = fac*df;
f2 = df11/2:df11:df*round(n/2);
vf2 = [];
for ii = 1:floor(length(f2))
    vf2(:,ii) = mean(varf1(:,(ii-1)*fac+1:ii*fac),2);
end
% figure; plot(f,zsf);
figure(2);
varmax = [2 2 2 1 1 1 0.5 0.5 0.5];
for i = 1:length(xhrms)
    subplot(3,3,i);
    plot(fef{i},ef{i},'r'); hold on;
    plot(f2,vf2(i,:),'k','LineWidth',1.5);
    axis([0 0.5 0 varmax(i)]);
    xlabel('f [Hz]'); ylabel('S\eta\eta [m^2/s]');
end
print variance_spectra.png -dpng

% water surface elevations
load(['F:\TU_Delft_work\deltagoot\coastal_engineering\test8.mat']);
eta = []; u = []; t = 0;
for i = 1:length(d)
    t = [t d(i).t'+t(end)];
    temp = []; 
    for ii = 1:length(xhrms)
        temp(ii,:) = m(i).eta{ii};
    end
    eta = [eta temp];
    u = [u d(i).u(:,1)'];
end
t = t(2:end);

tstart = 15000 % 7400;
tend =  15300 % 7700;
figure;
for i = 1:length(xhrms);
    subplot(3,3,i);
    plot(t,eta(i,:),'r'); hold on;
    plot(ts,zs(ind(i),:),'k','LineWidth',1.5);
    axis([tstart tend -1 1]);
    xlabel('t [s]'); ylabel('eta [m]');
end
print water_surface_elevations.png -dpng

% figure;
% for i = 1:length(xhrms);
%     subplot(3,3,i);
%     plot(t,eta(i,:),'r'); hold on;
%     plot(ts,zs(ind(i),:),'k','LineWidth',1.5);
%     axis([tstart tend -1 1]);
%     xlabel('t [s]'); ylabel('eta [m]');
% end
% print flow_velocities_elevations.png -dpng

% morphodynamics
figure(2);
subplot(211);
plot(xw,s.Cm*par.rhos,'k-','LineWidth',1.5); hold on; plot(xc+dxext,Cm,'ks','LineWidth',1.5);
xlabel('x [m]'); ylabel('C_{mean} [g/l]'); axis([min(min(xw)) max(max(xw)) 0 20]);
subplot(212);
plot(xw,s.Sdzb,'k--','LineWidth',1.5); hold on; plot(x+dxext,Sdzb,'k-','LineWidth',1.5);
xlabel('x [m]'); ylabel('S_{mean} [m^3/m/s]'); axis([min(min(xw)) max(max(xw)) -3E-4 1E-4]);
print('transport.png','-dpng');


figure(3)
for i = 1:length(Tout)
    subplot(3,2,i)
    plot(xw,s.zb_interval(:,1),'k-',xw,s.zb_interval(:,i),'r--',x+dxext,z(i,:),'r-','LineWidth',1.5);
    xlabel('x [m]'); ylabel('z_{b} [m]'); axis([170+dxext 220+dxext -2. 2]);
    title([num2str(round(Tout(i)*par.morfac/3600*10)/10) ' hr'])
end
print('profile.png','-dpng');


% incoming versus outgoing long waves
figure(4);
subplot(221);
plot(xw,s.Hrms_lfm,'k','LineWidth',1.5); hold on; plot(xhrms+dxext,Hrms_lf,'kv','LineWidth',1.5);
plot(xw,s.Hrms_lfm_in,'b','LineWidth',1.5);
plot(xw,s.Hrms_lfm_out,'b--','LineWidth',1.5);
plot(xw,sqrt(s.Hrms_lfm_in.^2+s.Hrms_lfm_out.^2),'r--','LineWidth',1.5);
xlabel('x [m]'); ylabel('H_{rms} [m]'); axis([min(min(xw)) max(max(xw)) 0 0.75]);
% subplot(222);
% plot(xw,s.rho,'k','LineWidth',1.5);
% xlabel('x [m]'); ylabel('\rho [-]'); axis([min(min(xw)) max(max(xw)) -1 1]);
% subplot(223);
% plot(xw,s.R,'k','LineWidth',1.5);
% xlabel('x [m]'); ylabel('R [W/m^2]'); axis([min(min(xw)) max(max(xw)) -2 10]);
% print('long_waves.png','-dpng');
% 
pause(1.0)

%fclose all; %close all;