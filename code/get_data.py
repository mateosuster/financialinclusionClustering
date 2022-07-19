
import wbdata
import pandas as pd
import os

os.chdir("C:/Users/mateo/Documents/repos/financialinclusionClustering")
# os.chdir('/home/mateo1/repos/financialinclusionClustering')

# rcParams['figure.figsize'] = 40, 12

# wbdata.get_source()

# indicadores = pd.DataFrame(wbdata.get_indicator(source=28) )

# ind_dic ={}
# for i in indicadores.loc[:,"id"].values:
#     ind_dic[i]= i


# data = wbdata.get_dataframe(ind_dic , country=['USA','ARG'])

# wbdata.get_data("IC.BUS.EASE.XQ", country="USA")


# levanto datasets
series = pd.read_csv("data/FINDEXSeries.csv").sort_values(by="Indicator Name", ascending=True)
countries = pd.read_csv("data/FINDEXCountry.csv")
raw_data= pd.read_csv("data/FINDEXData.csv")

# selecciono variables
var_dict = {
             #indicadores de acceso y uso de servicios financieros
               # Acceso
            # "account.t.d" :"account", # Account
            "fin1.t.d": "fin_account", #Financial institution account
            # aditional variables

            # "fin2.t.a", #Debit card ownership
           # "fin4.t": "debit_c_purch",  # Used a Debit card  to make a purchase in the past year (% age 15+)
            # "fin7.t.a", #Credit card ownership (% age 15+)
           "fin8.t": "credit_c_purch",  # Credit card used in the past year (% age 15+)
            "mobileaccount.t.d": "mm_account",  # Mobile money account %

             # Usage
            "borrow.any": "borrow_any",  # Borrowed any money in the past year (% age 15+)
            "save.any": "save_any",  # Saved any money in the past year (% age 15+)
        #   "fin22a.c.t.d": "borrow_fin_acc", #Borrowed from a formal financial institution  (% age 15+)
            "fin17a.t.d": "save_fin_acc",  # Saved at a financial institution (% age 15+)

        # barriers
            "fin11c": "lack_doc", # No account because of lack of necessary documentation
        "fin11a.s": "distance", # No account because financial institions are too far
        # "fin10.1a": "distance", # Reason for not using their inactive account: bank or financial institution is too far away (% with an inactive account, age 15+)
        "fin11d": "lack_trust", # No account because of lack of trust
        # "fin10.1e": "lack_trust", # Reason for not using their inactive account: don't trust banks or financial institutions (% age 15+)
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
pre_data = raw_data.drop(["Unnamed: 8"], axis=1).\
    melt(id_vars = ["Country Name", "Country Code","Indicator Name", "Indicator Code"],
         value_vars = ["2011", "2014", "2017", "2021"],
         var_name="year")  # rotacion de la tabla

## seleccion de variables y filtro de regiones
filter_data = pre_data[(pre_data["Indicator Code"].isin( var_list)) &(pre_data["Country Code"].isin(countries.loc[countries["Region"].notnull() , "Country Code"].values)) ]


# dataset final
dataset = filter_data.drop("Indicator Name", axis=1).pivot(index = ["Country Name", "Country Code", "year"] ,
                                                        columns = "Indicator Code",
                                                        values ="value") /100 #.reset_index()
# data = filter_data.drop("Indicator Code", axis=1).pivot(index = ["Country Name", "Country Code", "year"] , columns = "Indicator Name", values ="value")#.reset_index()
dataset.rename(columns = var_dict,inplace=True)

dataset.to_csv("data/data.csv", index=True) #exportacion de dataset

