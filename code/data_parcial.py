####################################
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
