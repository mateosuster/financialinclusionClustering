
import wbdata
import pandas as pd
import os

# os.chdir("C:/Users/mateo/Documents/repos/financialinclusionClustering")
os.chdir('/home/mateo1/repos/financialinclusionClustering')

# rcParams['figure.figsize'] = 40, 12

# wbdata.get_source()

# indicadores = pd.DataFrame(wbdata.get_indicator(source=28) )

# ind_dic ={}
# for i in indicadores.loc[:,"id"].values:
#     ind_dic[i]= i


# data = wbdata.get_dataframe(ind_dic , country=['USA','ARG'])

# wbdata.get_data("IC.BUS.EASE.XQ", country="USA")


# levanto datasets
series = pd.read_csv("data/FINDEXSeries.csv")
countries = pd.read_csv("data/FINDEXCountry.csv")
raw_data= pd.read_csv("data/FINDEXData.csv")

# selecciono variables
var_dict = {
             #indicadores de acceso y uso de servicios financieros
             "account.t.d" :"account", # Account
             "fin1.t.a": "fin_account", #Financial institution account
             "fin17a.t.a": "saved_fin_acc", #Saved at a financial institution (% age 15+)
             "fin22a.t.d": "borrowed_fin_acc", #Borrowed from a financial institution or used a credit card (% age 15+)

             #aditional variables
             "fin18.t.d": "saved_any_money", #Saved any money in the past year (% age 15+)
             "fin23.t.d": "borrowed_any_money", #Borrowed any money in the past year (% age 15+)
             # "fin2.t.a", #Debit card ownership
             "fin4.t.a" :"debit_card_purch", #Debit card used to make a purchase in the past year (% age 15+)
             # "fin7.t.a", #Credit card ownership (% age 15+)
             "fin8.t.a": "credit_card_purch", #Credit card used in the past year (% age 15+)
             }



var_list = list(var_dict.keys())
gender_variables= []
labor_variables= []
educational_variables = []
income_variables= []
for v in var_list :
    gender_variables.append(v+".1") #Male
    gender_variables.append(v+".2") #Female
    labor_variables.append(v+".10") #in labor force
    labor_variables.append(v+".11") #out of labor force
    educational_variables.append(v+".5") #primary education or less
    educational_variables.append(v+".6") #secondary education or more
    income_variables.append(v+".7") #poorest 40%
    income_variables.append(v+".8") #richest 60%


var_desc = series[series["Series Code"].isin(var_list)] #desclasificador de variables


#preprocesamiento
pre_data = raw_data.drop(["Unnamed: 7"], axis=1).\
    melt(id_vars = ["Country Name", "Country Code","Indicator Name", "Indicator Code"], value_vars = ["2011", "2014", "2017"], var_name="year")  # rotacion de la tabla

## seleccion de variables y filtro de regiones
filter_data = pre_data[(pre_data["Indicator Code"].isin( var_list)) &(pre_data["Country Code"].isin(countries.loc[countries["Region"].notnull() , "Country Code"].values)) ]

# dataset final
# data = filter_data.drop("Indicator Code", axis=1).pivot(index = ["Country Name", "Country Code", "year"] , columns = "Indicator Name", values ="value")#.reset_index()
data = filter_data.drop("Indicator Name", axis=1).pivot(index = ["Country Name", "Country Code", "year"] , columns = "Indicator Code", values ="value")#.reset_index()
data.rename(columns = var_dict,inplace=True)

data.to_csv("data/data.csv") #exportacion de dataset


data_parcial = pre_data[(pre_data['Indicator Code'].isin(['fin1.t.a.1',
                                                          'fin1.t.a.2',
                                                          'fin18.t.d.1',
                                                          'fin18.t.d.2'])) 
                        &(pre_data["Country Code"].isin(countries.loc[countries["Region"].notnull() , "Country Code"].values))]

data_parcial= pd.merge(data_parcial, countries[["Country Code", "Region"]] , how ="left", on = "Country Code")

x = data_parcial.pivot(index = ['Region', 'Country Name', 'Country Code', 'year'] , 
                   columns = 'Indicator Name', 
                   values = 'value')

x.to_csv('/home/mateo1/docencia/data_parcial_2.csv')

data_parcial.info()

len(pd.unique(data_parcial['Country Name']))
