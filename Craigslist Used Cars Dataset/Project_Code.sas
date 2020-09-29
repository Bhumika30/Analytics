dm 'clear log'; dm 'clear output';

libname project 'E:\Users\jxs190031\Documents\My SAS Files\Codes\Project';
title;

	* Import dataset
	* Vehicles data;
proc import out= project.UsedCarsProject
			datafile= 'E:\Users\jxs190031\Documents\My SAS Files\Codes\Project\vehicles.csv'
			dbms=csv replace;
		getnames = yes;
		datarow=2;
run;
proc contents data=project.UsedCarsProject;
run;

	* Modifying SAS data;
	* Check the price and odometer columns;

proc means data=project.UsedCarsProject
	maxdec=2 fw=10 printalltypes
	n mean median std q1 q3 QRANGE min max; *n mean median std q1 q3 QRANGE;
	VAR price odometer;
	title 'Statistics for Numeric columns';
RUN;
	* Drop the columns with all unique values in each record and most of missing records;
data project.UsedCarsProject1;
	set project.UsedCarsProject
	(drop =  url: region_url: image_url lat long vin id description county size );  /* ":" is the wild character */
run;

	* Checking the count of missing values;
proc format;
 value $missfmt ' '='Missing' other='Not Missing';
 value  missfmt  . ='Missing' other='Not Missing';
run;

	* Conclusion: 
1. The missing count shows that there is more than 70% of data missing in the size column
   of the dataset. So the column can be dropped. 
2. We can drop the column county as more than 99% of data is missing.
3. around 67% of data is missing in size column.
4. For cylinder column, we can replace the missing values grouping by model and taking mode of the group.
5. Replace the missing values in type with mode of group by model and year.;
 
proc freq data=project.UsedCarsProject1; 
	format _CHAR_ $missfmt.; /* apply format for the duration of this PROC */
	tables _CHAR_ / missing missprint nocum nopercent;
	format _NUMERIC_ missfmt.;
	tables _NUMERIC_ / missing missprint nocum nopercent;
	title 'Count Missing values for all variables';
run;

	* Delete extreme observations and create a log price variable; 
data project.UsedCarsProject2;
	set project.UsedCarsProject1(where=(price between 1 and 50000));
run;

data project.UsedCarsProject3;
	set project.UsedCarsProject2(where=(odometer between 0 and 400000));
	logPrice = log(price);
run;

	* Check distribution of Price variable;
ods graphics / imagemap=on;
	
proc univariate data=project.UsedCarsProject3 plots;
	var price;
	title 'Distribution analysis for price';
run;

	* Check distribution on Price, log(Price), and Odometer;
proc univariate data=project.UsedCarsProject3 normal noprint;
	var price logPrice odometer;
	histogram price logPrice odometer / normal kernel; /* use weibull distribution to check */
	inset n mean std / position = ne;
	probplot logPrice;
	title "Distribution Analysis - Continous Variables";
run;

	* Create variable Age;
data project.UsedCarsProject4;
	set project.UsedCarsProject3;
	Age=2020 - Year;
run;

	* Content check after above preprocessing;
proc contents data=project.UsedCarsProject4;
	title 'Content description after outliers removed and columns dropped';
run;
	* Frequency distribution for paint_color of the car;
ods graphics / imagemap=on;


   proc chart data=project.UsedCarsProject4;
   hbar paint_color;
   title 'Frequency distribution for paint_color of the car';
run;
	* Check min and max of the price group by the paint_color of car;
	* Conclusion: Most of the cars with higher median and min price are for black and white cars, 
	while grey cars contribute to the aproximate 10% of the data. We can label all the other paint_colors as others;
proc means data=project.UsedCarsProject4 n mean median max min ;
	class paint_color;
	var price;
	title 'price stats as per the car color';
run;
data project.UsedCarsProject5;
	set project.UsedCarsProject4(where=(age between 0 and 35));
	logAge = log(Age);
run;

	* Check distribution on Age;
proc univariate data=project.UsedCarsProject5 plots;
	var age;
run;

proc univariate data=project.UsedCarsProject5 plots;
	var logAge;
run;

	* Check distribution on Odometer;
proc univariate data=project.UsedCarsProject5 plots;
	var odometer;
run;
	
	* Check distribution on Age;
proc univariate data=project.UsedCarsProject5 plots;
	var year;
run;


	* Fequency Plots;
proc freq data=project.UsedCarsProject5;
	tables fuel  / plots= freqplot(twoway=stacked orient=horizontal);
	title "Frequency Analysis - Fuel";
run;
proc freq data=project.UsedCarsProject5;
	tables title_status  / plots= freqplot(twoway=stacked orient=horizontal);
	title "Frequency Analysis - title";
run;
proc freq data=project.UsedCarsProject5;
	tables transmission  / plots= freqplot(twoway=stacked orient=horizontal);
	title "Frequency Analysis - Transmission";
run;
proc freq data=project.UsedCarsProject5;
	tables type  / plots= freqplot(twoway=stacked orient=horizontal);
	title "Frequency Analysis - Type";
run;
proc freq data=project.UsedCarsProject5;
	tables condition  / plots= freqplot(twoway=stacked orient=horizontal);
	title "Frequency Analysis - Condition";
run;
proc freq data=project.UsedCarsProject5;
	tables cylinders  / plots= freqplot(twoway=stacked orient=horizontal);
	title "Frequency Analysis - Cylinders";
run;
proc freq data=project.UsedCarsProject5;
	tables paint_color  / plots= freqplot(twoway=stacked orient=horizontal);
	title "Frequency Analysis - Color";
run;

proc freq data=project.UsedCarsProject5;
	tables state  / plots= freqplot(twoway=stacked orient=horizontal);
	title "Frequency Analysis - State";
run;

	* Pie chart with vehicle types;
goptions reset=all cback=white border htitle=12pt htext=10pt;  
title1 "Types of Vehicles";
proc gchart data=project.UsedCarsProject5;
   pie type / other=0
              midpoints="Truck" "SUV" "Sedan" "Wagon" "Sports" "Hybrid"
              value=none
              percent=arrow
              slice=arrow
              noheading 
              plabel=(font='Albany AMT/bold' h=1.3 color=depk);
run;
quit; 


	* Scatter plot for prive v/s odometer;
proc sgscatter data=project.UsedCarsProject5;
plot price*odometer;
title 'Scatter Plots of price versus odometer';
run;

	* Check relationship between variables;
proc sgplot data=project.UsedCarsProject5;
  title "Relationship between price and odometer";
	 scatter y=odometer x=price;
	 keylegend / location=inside position=bottomright;
run;

proc sgplot data=project.UsedCarsProject5;
  title "Relationship between price and Age";
	 scatter y=Age x=price;
	 keylegend / location=inside position=bottomright;
run;

proc sgplot data=project.UsedCarsProject5;
  title "Relationship between fuel and Age";
	 scatter y=fuel x=price;
	 keylegend / location=inside position=bottomright;
run;

proc sgscatter data=project.UsedCarsProject5; 
	plot (fuel)*price;
	title "Relationship between fuel and Price";
run;

proc sgscatter data=project.UsedCarsProject5; 
	plot (fuel)*price;
	title "Relationship between fuel and Price";
run;
proc sgscatter data=project.UsedCarsProject5; 
	plot (condition)*price;
	title "Relationship between condition and Price";
run;

proc sgscatter data=project.UsedCarsProject5; 
	plot (drive)*price;
	title "Relationship between drive and Price";
run;

 proc sgpanel data=project.UsedCarsProject5;
  panelby transmission;
  hbar age /
    response=price
    stat=mean;
	title "Price v/s age and transmission (combined)";
run;

 proc sgpanel data=project.UsedCarsProject5;
  panelby condition;
  hbar age /
    response=price
    stat=mean;
	title "Price v/s age and condition (combined)";
run;
*Regression: price v/s Odometer;

ods graphics on;
proc reg data=project.UsedCarsProject5;
	model price = odometer;
	title "Reg1: Model with price and odometer";
	run;
quit;  

proc sgplot data=project.UsedCarsProject5;
  	Polynommodel1: reg x=price y=odometer / lineattrs=(color=brown pattern= solid)
       legendlabel="Linear";	
	title2 "Linear Model";
run;

proc sgplot data=project.UsedCarsProject5;
   	Polynommodel2: reg x=price y=odometer / degree=2 lineattrs=(color=green pattern=mediumdash) 
		legendlabel="2nd Degree";
	title2 "Second Degree Polynomial";
run;

proc sgplot data=project.UsedCarsProject5;
   	Polynommodel3: reg x=price y=odometer / degree=3 lineattrs=(color=red pattern=shortdash)
		legendlabel="3rd Degree";
	title2 "Third Degree Polynomial";
run;

proc sgplot data=project.UsedCarsProject5;
	Polynommodel4: reg x=price y=odometer / degree=4 lineattrs=(color=blue pattern=longdash) 
	legendlabel="4th Degree";
	title2 "Fourth Degree Polynomial";
run;

	* Use 4th-degree polynomial as the highest-degree model;

proc glmselect data=project.UsedCarsProject5 outdesign=d_usedCars;
	effect p_odometer=polynomial(odometer / degree = 4);
	FourDegrees_GLM: model price = p_odometer / selection = none;
	title "Quadratic Polynomial using UsedCars Dataset";
run;

*(vi) Then use PROC REG with the &_GLSMOD macro variable and the
DIAGNOSTICS plot option to request diagnostic plots. Write down the code.;

proc reg data=d_usedCars plots (unpack) = (diagnostics (stats=none));
	Cubic_Model: model price = &_GLSMOD / lackfit;
	title "Diagnostic plots: UsedCars Data";
run;

* Generate Diagnostic Plots with Regression;
proc contents data=project.UsedCarsProject5;
	run;

%let interval=Age odometer;

ods graphics on;
proc reg data=project.UsedCarsProject5;
	continous: model price = &interval;
	title "Price Model - Generate Diagnostic Plots";
run;
quit;

	ods graphics on;
proc sgscatter data = project.UsedCarsProject5;
	matrix &interval;
	title "Correlation Plot";
run;

proc corr data = project.UsedCarsProject5 nosimple;
	var &interval;
	with score;
	title "Correlation Coefficients";
run;

proc reg data=project.UsedCarsProject5;
   wSCORE: model price = &interval / vif;
   title 'Collinearity Diagnostics';
run;
quit;

ods graphics on;
proc glmselect data=project.UsedCarsProject5 outdesign=d_cars;
	effect p_odometer=polynomial(odometer / degree = 4);
	FourDegrees_GLM: model price = p_odometer / selection = none;
	title "Quadratic Polynomial using Cars Dataset";
run;

*(vi) Then use PROC REG with the &_GLSMOD macro variable and the
DIAGNOSTICS plot option to request diagnostic plots. Write down the code.;

proc reg data=d_cars plots (unpack) = (diagnostics (stats=none));
	Cubic_Model: model price = &_GLSMOD / lackfit;
	title "Diagnostic plots: Cars Data";
run;
