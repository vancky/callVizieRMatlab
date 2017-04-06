classdef queryVizieRTest < matlab.unittest.TestCase    
    % test for queryVizieR 
    % do it by 
    %  >> runtests('queryVizieRTest')
    properties (TestParameter)
    end
    methods (Test)
        function query_urat1(test)
            target = queryVizieR(10.684708,41.232,2,4);
            target=target.get_urat1();
            test.verifyEqual(target.getitem('RA',5),10.702985800);
            test.verifyEqual(target.getitem('DE',8),41.2264053);
            test.verifyEqual(target.getitem('e_fmag',2),nan);
            test.verifyEqual(target.getitem('Bmag',6),16.2450);
            test.verifyEqual(target.getitem('Bmag',5),nan);
            test.verifyEqual(target.getitem('imag',5),nan);
            test.verifyEqual(target.getitem('URAT1',7),{'657-010470'});
        end
          function query_gaiadr1(test)
            target = queryVizieR(136.8592916,dms2degrees([15,3,28.2]),2,4);
            target=target.get_gaiadr1();
            test.verifyEqual(target.getitem('RA',2),136.8614508341);
            test.verifyEqual(target.getitem('DE',5),15.0744504203);
            test.verifyEqual(target.getitem('Gmag',2),15.717);
            test.verifyEqual(target.getitem('pmRA',1),nan); 
          end
           function query_ppmxl(test)
            target = queryVizieR(72.7746744,43.6744847,10,10);
            target=target.get_ppmxl();
            test.verifyEqual(target.getitem('RA',1020),72.863900);
            test.verifyEqual(target.getitem('DE',1000),43.691135);
            test.verifyEqual(target.getitem('Jmag',954),nan);
            test.verifyEqual(target.getitem('pmRA',101),-20.4); 
             test.verifyEqual(target.getitem('f1',124),10); 
          end
    end
    
end

