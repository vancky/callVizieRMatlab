classdef queryVizieR
    % query gaia Dr1,URAT1 with VizieR
    % see http://cdsarc.u-strasbg.fr/doc/asu-summary.htx
    % and http://cds.u-strasbg.fr/doc/asu.html
    % for details , now it's a easy mode
    % only support for a box region !
    % fisrt version 2017/3/20 by lifan@pmo.ac.cn
    % useage:
    %         t=queryVizieR(10.684708,41.232,2,4);
    %         t=t.get_urat1();
    %         disp(t.fields)
    %         summary(t.data);
    properties
        center
        box
        url
        data
        originSrc
        source
        hostname
    end
    
    methods % constructor methods
        function self = queryVizieR(ra,dec,boxx,boxy)
            % Input:
            % ra : RA of the center, unit: deg;
            % dec : DEC of the center, unit: deg;
            % boxx: a rectangular box in the tangential projection centered on the given position
            % boxy: where boxx and boxy are expressed in decimal arc minutes.
            self.center.ra=ra;
            self.center.dec=dec;
            self.box.x=boxx;
            self.box.y=boxy;
            self.url            = nan;
            self.data           = nan;
            self.source         = nan;
            self.hostname='http://vizier.u-strasbg.fr/';
          %  self.hostname='http://vizier.cfa.harvard.edu/';
        end
    end
    properties (Dependent)
        fields
        queryUrl
        starNo
    end
    % methods of properties !
    methods
        function tt=get.fields(self)
            % returns list of available properties for all epochs
            % example:
            %         t=queryVizieR(10.684708,41.232,2,4);
            %         t=t.get_urat1();
            %         disp(t.fields)
            try
                tt=self.data.Properties.VariableNames;
            catch
                tt=[];
            end
        end
        function tt=get.starNo(self)
            % returns total number of stars that have been returned
            try
                tt=size(self.data,1);
            catch
                tt=0;
            end
        end
        function tt=get.queryUrl(self)
            % returns URL that has been used in calling VizieR
            try
                tt=self.url;
            catch
                tt=[];
            end
        end
        
        function tt=getitem(self,key,k)
            %
            %             provides access to query data
            %
            %         Parameters
            %         ----------
            %         key          : str/int
            %            epoch index or property key
            %
            %         Returns
            %         -------
            %         query data according to key
            %         example:
            %         t=queryVizieR(10.684708,41.232,2,4);
            %         t=t.get_urat1();
            %         disp(t.fields)
            %         myNeed=t.getitem({'RA','DEC','Jmag'});
            %
            
            if isempty(self.data)
                disp('queryVizieR ERROR: run get_gaia or get_urat1 first');
                tt=nan;
            else
                if nargin>2&&max(k)<=self.starNo&&min(k)>0
                    tt=self.data{k,key};
                elseif nargin>2&&(max(k)>self.starNo||min(k)<0)&&k~=':'
                    error('out of index')
                else
                    tt=self.data{:,key};
                end
            end
        end
    end
    % the main query function !
    methods
        function self=get_urat1(self)
            % A easist mode query urat1 online
            % example url is
            % http://vizier.u-strasbg.fr/viz-bin/asu-txt?-source=I/329/urat1&-c.ra=10.6847&-c.dec=41.2687&-c.bm=4/2
            % example:
            %         t=queryVizieR(10.684708,41.232,2,4);
            %         t=t.get_urat1();
            %         disp(t.fields)
            %         summary(t.data)
            self.source='I/329/urat1';
            tmpurl=strcat(self.hostname,'viz-bin/asu-txt?',...
                '-source=',self.source,sprintf('&-c.ra=%f&-c.dec=%f',self.center.ra,self.center.dec),...
                sprintf('&-c.bm=%f/%f',self.box.x,self.box.y));
            self.url=tmpurl;
            %   disp(self.url);
            src=webread(self.url);
            self.originSrc=src;
            fieldnames={'URAT1','RA','DE','Ep',...
                'fmag','e_fmag','pmRA','pmDE','Jmag','Hmag','Kmag','Bmag','Vmag','gmag',...
                'rmag','imag'};
            % get posizition of  data in origin source file
            pos1=regexp(src,'------\n\d','ONCE','end');
            pos2=regexp(src,'\n#END#','ONCE','start');
            % from uiimport
            % read fixed width text
            formatSpec = '%10s%12s%12s%9s%7s%7s%7s%7s%7s%7s%7s%7s%7s%7s%7s%[^\n\r]';
            try
                C= textscan(src(pos1:pos2),formatSpec, 'Delimiter', '', 'WhiteSpace', '',  'ReturnOnError', false);
            catch
                error('check source file %s\n',src);
            end
            for k=2:length(C)
                C{k}=cell2mat(cellfun(@str2double,C{k},'UniformOutput', false));
            end
            self.data=table(C{1:end},'VariableNames',fieldnames);
            % add unit and comments
            self.data.Properties.VariableDescriptions{1} = 'URAT1 recommended identifier (ZZZ-NNNNNN)';
            self.data.Properties.VariableUnits{2} = 'deg';self.data.Properties.VariableDescriptions{2}='Right ascension on ICRS, at "Epoch"';
            self.data.Properties.VariableUnits{3} = 'deg';self.data.Properties.VariableDescriptions{3}='Declination on ICRS, at "Epoch"';
            self.data.Properties.VariableUnits{4} = 'yr';self.data.Properties.VariableDescriptions{4}='Mean URAT observation epoch';
            self.data.Properties.VariableUnits{5} = 'mag';self.data.Properties.VariableDescriptions{5}='mean URAT model fit magnitude';
            self.data.Properties.VariableUnits{6} = 'mag';self.data.Properties.VariableDescriptions{6}='URAT photometry error';
            self.data.Properties.VariableUnits{7} = 'mas/yr';self.data.Properties.VariableDescriptions{7}='Proper motion RA*cosDec (from 2MASS)';
            self.data.Properties.VariableUnits{8} = 'mas/yr';self.data.Properties.VariableDescriptions{8}='Proper motion in Declination ';
            self.data.Properties.VariableUnits{9} = 'mag';self.data.Properties.VariableDescriptions{9}='2MASS J-band magnitude';
            self.data.Properties.VariableUnits{10} = 'mag';self.data.Properties.VariableDescriptions{10}='2MASS H-band magnitude';
            self.data.Properties.VariableUnits{11} = 'mag';self.data.Properties.VariableDescriptions{11}='2MASS Ks-band magnitude';
            self.data.Properties.VariableUnits{12} = 'mag';self.data.Properties.VariableDescriptions{12}='APASS B-band magnitude ';
            self.data.Properties.VariableUnits{13} = 'mag';self.data.Properties.VariableDescriptions{13}='APASS V-band magnitude';
            self.data.Properties.VariableUnits{14} = 'mag';self.data.Properties.VariableDescriptions{14}='APASS g-band magnitude';
            self.data.Properties.VariableUnits{15} = 'mag';self.data.Properties.VariableDescriptions{15}='APASS r-band magnitude';
            self.data.Properties.VariableUnits{16} = 'mag';self.data.Properties.VariableDescriptions{16}='APASS i-band magnitude';
        end
        function self=get_gaiadr1(self)
            % A easist mode query gaia online
            % example url is
            % http://vizier.u-strasbg.fr/viz-bin/asu-txt?-source=I/337/gaia&-c.ra=10.6847&-c.dec=41.2687&-c.bm=4/2
            %  example:
            %         t=queryVizieR(10.684708,41.232,2,4);
            %         t=t.get_gaiadr1();
            %         disp(t.fields)
            %         summary(t.data)
            self.source='I/337/gaia';
            tmpurl=strcat(self.hostname,'viz-bin/asu-txt?',...
                '-source=',self.source,sprintf('&-c.ra=%f&-c.dec=%f',self.center.ra,self.center.dec),...
                sprintf('&-c.bm=%f/%f',self.box.x,self.box.y));
            self.url=tmpurl;
            %   disp(self.url);
            src=webread(self.url);
            self.originSrc=src;
            fieldnames={'RA','e_RA','DE','e_DE',...
                'GAIA_ID','parallax','pmRA','pmDE','RADEcor','Dup','GF','e_GF','Gmag','Var'};
            pos1=regexp(src,'-------------\n\d','ONCE','end');
            pos2=regexp(src,'\n#END#','ONCE','start');
            % from uiimport
            % read fixed width text
            formatSpec = '%14s%7s%15s%8s%20s%7s%10s%10s%7s%2s%12s%12s%7s%[^\n\r]';
            try
                C= textscan(src(pos1:pos2),formatSpec, 'Delimiter', '', 'WhiteSpace', '',  'ReturnOnError', false);
            catch
                error('check source file %s\n',src);
            end
            for k=[1,2,3,4,6,7,8,9,10,11,12,13]
                C{k}=cell2mat(cellfun(@str2double,C{k},'UniformOutput', false));
            end
            self.data=table(C{1:end},'VariableNames',fieldnames);
            self.data.Properties.VariableUnits{1} = 'deg';self.data.Properties.VariableDescriptions{1} = 'Right ascension (ICRS) at epoch 2015.0';
            self.data.Properties.VariableUnits{2} = 'mas';self.data.Properties.VariableDescriptions{2}='Standard error of right ascension';
            self.data.Properties.VariableUnits{3} = 'deg';self.data.Properties.VariableDescriptions{3}='Declination (ICRS) at epoch 2015.0';
            self.data.Properties.VariableUnits{4} = 'mas';self.data.Properties.VariableDescriptions{4}='Standard error of declination ';
            self.data.Properties.VariableDescriptions{5}='Source ID';
            self.data.Properties.VariableUnits{6} = 'mas';self.data.Properties.VariableDescriptions{6}='Absolute barycentric stellar parallax of the source at the reference epoch Epoch';
            self.data.Properties.VariableUnits{7} = 'mas/yr';self.data.Properties.VariableDescriptions{7}='Proper motion in right ascension direction';
            self.data.Properties.VariableUnits{8} = 'mas/yr';self.data.Properties.VariableDescriptions{8}='Proper motion in declination direction  ';
            self.data.Properties.VariableDescriptions{9}='Correlation between right ascension and declination';
            self.data.Properties.VariableDescriptions{10}='Source with duplicate sources';
            self.data.Properties.VariableUnits{11} = 'e-/s';self.data.Properties.VariableDescriptions{11}='G-band mean flux';
            self.data.Properties.VariableUnits{12} = 'e-/s';self.data.Properties.VariableDescriptions{12}='Error on G-band mean flux';
            self.data.Properties.VariableUnits{13} = 'mag';self.data.Properties.VariableDescriptions{13}='G-band mean magnitude';
            self.data.Properties.VariableDescriptions{14}='Photometric variability flag';
        end
        function self=get_ppmxl(self)
            % A easist mode query urat1 online
            % example url is
            % http://vizier.u-strasbg.fr/viz-bin/asu-txt?-source=I/317/sample&-c.ra=10.6847&-c.dec=41.2687&-c.bm=4/2
            % example:
            %         t=queryVizieR(10.684708,41.232,2,4);
            %         t=t.get_ppmxl();
            %         disp(t.fields)
            %         summary(t.data)
            self.source='I/317/sample';
            tmpurl=strcat(self.hostname,'viz-bin/asu-txt?',...
                '-source=',self.source,sprintf('&-c.ra=%f&-c.dec=%f',self.center.ra,self.center.dec),...
                sprintf('&-c.bm=%f/%f',self.box.x,self.box.y));
            self.url=tmpurl;
            %   disp(self.url);
            src=webread(self.url);
            self.originSrc=src;
            fieldnames={'RA','DE','pmRA','pmDE','Jmag','Kmag','b1mag','b2mag',...
                'r1mag','r2mag','imag','No','f1'};
            try
                pos1=regexp(src,'--\n\d','ONCE','end');
                pos2=regexp(src,'\n#END#','ONCE','start');
            catch
                error('no stars in the box in catalogue,please check source file %s\n',src);
            end
            % read fixed width text
            formatSpec = '%10s%11s%9s%9s%7s%7s%6s%6s%6s%6s%6s%3s%[^\n\r]';
            try
                C= textscan(src(pos1:pos2),formatSpec, 'Delimiter', '', 'WhiteSpace', '',  'ReturnOnError', false);
            catch
                error('check source file %s\n',src);
            end
            for k=1:size(C,2)
                C{k}=cell2mat(cellfun(@str2double,C{k},'UniformOutput', false));
            end
            self.data=table(C{1:end},'VariableNames',fieldnames);
            % add unit and comments
            self.data.Properties.VariableUnits{1} = 'deg';self.data.Properties.VariableDescriptions{1}='Right Ascension J2000.0, epoch 2000.0';
            self.data.Properties.VariableUnits{2} = 'deg';self.data.Properties.VariableDescriptions{2}='Declination J2000.0, epoch 2000.0';
            self.data.Properties.VariableUnits{3} = 'mas/yr';self.data.Properties.VariableDescriptions{3}='Proper Motion in RA*cos(DEdeg)';
            self.data.Properties.VariableUnits{4} = 'mas/yr';self.data.Properties.VariableDescriptions{4}='Proper Motion in Dec';
            self.data.Properties.VariableUnits{5} = 'mag';self.data.Properties.VariableDescriptions{5}='2MASS J-band magnitude';
            self.data.Properties.VariableUnits{6} = 'mag';self.data.Properties.VariableDescriptions{6}='2MASS Ks-band magnitude';
            self.data.Properties.VariableUnits{7} = 'mag';self.data.Properties.VariableDescriptions{7}='B mag from USNO-B, first epoch';
            self.data.Properties.VariableUnits{8} = 'mag';self.data.Properties.VariableDescriptions{8}='B mag from USNO-B, second epoch';
            self.data.Properties.VariableUnits{9} = 'mag';self.data.Properties.VariableDescriptions{9}='R mag from USNO-B, first epoch';
            self.data.Properties.VariableUnits{10} = 'mag';self.data.Properties.VariableDescriptions{10}='R mag from USNO-B, second epoch ';
            self.data.Properties.VariableUnits{11} = 'mag';self.data.Properties.VariableDescriptions{11}='Number of observations used';
            self.data.Properties.VariableDescriptions{12}='Flags';
        end
    end
    
    
end

