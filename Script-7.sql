-- LIMPIEZA DE DATOS CON SQL


-- Se crea la base de datos para importar la data "CVS"
create database if not exists Clean; 

use clean;

show TABLES;

-- Selecciona los primeros 20 registros de la tabla
select * from limpieza l limit 20;

-- Cuenta los registros de toda la tabla
select count(*) from limpieza l; 

/* Store procedure funcion que permite almacer un codigo para ejecutar
   mas adelante sin necesidad de volverlo a escribir
*/

DELIMITER //

CREATE PROCEDURE Lim()
BEGIN
    SELECT * FROM limpieza l;

 END //

DELIMITER ;


call Lim();

show procedure STATUS where db='clean';

-- Estadarizar las columnas de la tabla.
alter table limpieza change column `id?empleado` id_employee VARCHAR(20) null;
alter table limpieza change column `apellido` last_name VARCHAR(40) null;
alter table limpieza change column `género` gender VARCHAR(20) null;
alter table limpieza change column `Star_date` start_date VARCHAR(50) null;

-- Codigo para agrupar el id del empleado y saber la cantidad de duplicados

select id_employee , count(*) as cantidad_duplicados 
from limpieza l 
group by id_employee 
having count(*)>1
; 

-- Subconsulta para saber el numero total de id's duplicados

select count(*) as total_duplicados 
from(
select id_employee , count(*) as cantidad_duplicados 
from limpieza l 
group by id_employee 
having count(*)>1
) as subquery;

rename table limpieza to duplicados;

-- Creacion de tabla temporal para pasar los datos unicos a esta.

create temporary table temp_limpieza as 
select distinct * from duplicados;

select count(*) as original from duplicados;
select count(*) as sin_duplicados from temp_limpieza; 

-- Pasar todos los datos de la tabla temporal a una normal
create table Limpieza as select * from temp_limpieza;


drop table duplicados ;

call lim();


describe limpieza;

-- Selecciona los nombres que tengan espacios en blanco
select name from limpieza 
where length(name) - length( trim(name))>0;

-- Actualiza los nombres quitandole los espacios en blanco
update limpieza set name = trim(name)
where length(name) - length( trim(name))>0;



-- Selecciona los apellidos que tengan espacios en blanco
select last_name from limpieza 
where length(last_name) - length( trim(last_name))>0;


-- Actualiza los apellidos quitandole los espacios en blanco
update limpieza set last_name= trim(last_name)
where length(last_name ) - length( trim(last_name))>0;



-- Cambiar el idioma de los registros de la columna gender a ingles para estadarizar datos

/* Se realiza una transaccion para realizar la actualizacion 
   de los datos de manera segura	
   esto permite devolver la transaccion con un rollback 
   y devuleve los datos a su estado inical o efectuar los cambios
   con un commit                     
*/

start transaction;

 update limpieza set gender = 
  CASE
   when gender = 'hombre' then 'male'
   when gender = 'mujer' then 'female'
   else 'other'
   end;

 alter table limpieza modify column type varchar(50);

 update limpieza set type =
 CASE
  when type = '0' then 'Hybrid'
  when type = '1' then 'Remote'
  else 'Other'
 end;
 
commit;
 
describe limpieza ;

/* Limpieza en la columna salary remplazar signo "$" y 
   la coma en los valores ademas ajustar los decimales*/

start transaction;

update limpieza set salary = 
cast(trim(replace(replace(salary,'$',''),',','')) as decimal (15,2))

commit;

-- Cambiar tipo de dato de texto a numero. 
alter table limpieza modify column salary int null;

call lim();

-- Cambiar fechas

select birth_date, name,
case
 when birth_date like '%/%' then date_format((str_to_date(birth_date,'%m/%d/%y')),'%Y-%m-%d')
 when birth_date like '%-%' then date_format((str_to_date(birth_date,'%m-%d-%y')) ,'%Y-%m-%d')
 else null
 end as new_birth_date
from limpieza l ;


call lim();
describe limpieza ;


update limpieza set name = replace(name,';','') where name like '%;%';

-- Actualizar datos de fecha
start transaction; 

UPDATE limpieza
SET birth_date = CASE
    WHEN birth_date LIKE '%/%' AND STR_TO_DATE(birth_date, '%m/%d/%Y') IS NOT NULL THEN STR_TO_DATE(birth_date, '%m/%d/%Y')
    WHEN birth_date LIKE '%-%' AND STR_TO_DATE(birth_date, '%m-%d-%Y') IS NOT NULL THEN STR_TO_DATE(birth_date, '%m-%d-%Y')
    ELSE birth_date
END
WHERE (birth_date LIKE '%/%' OR birth_date LIKE '%-%'); 

alter table limpieza modify column birth_date date;


commit;


start transaction;

update limpieza set start_date = CASE
    WHEN start_date LIKE '%/%' AND STR_TO_DATE(start_date, '%m/%d/%Y') IS NOT NULL THEN STR_TO_DATE(start_date, '%m/%d/%Y')
    WHEN start_date LIKE '%-%' AND STR_TO_DATE(start_date, '%m-%d-%Y') IS NOT NULL THEN STR_TO_DATE(start_date, '%m-%d-%Y')
    ELSE start_date
END
WHERE (start_date LIKE '%/%' OR start_date LIKE '%-%'); 

commit;

alter table limpieza modify column start_date date;

describe limpieza ;


-- Ensayos del formato fecha para analizar como se veria para cada ocacion

-- Convierte el valor en objeto fecha (timestamp)
select finish_date ,str_to_date(finish_date,'%Y-%m-%d %H:%i:%s')as fecha from limpieza l;

-- se trasforma al formato fecha luego se le agrega la funcion str_to_date
select finish_date,date_format(str_to_date(finish_date,'%Y-%m-%d %H:%i:%s'),'%Y-%m-%d') as fecha from limpieza l;

-- Dividir unicamente la fecha con la funcion str_to_date

select finish_date,str_to_date(finish_date,'%Y-%m-%d') as fecha from limpieza l ;

-- #Diferencia str_to date y date_format

-- Separar solo la hora

-- NO FUNCIONA CON LA FUNCION STR_TO_DATE
select finish_date,str_to_date(finish_date,'%H:%i:%s') as hour_stamp  from limpieza l ;

-- Funcion date_format
select finish_date,date_format(finish_date,'%H:%i:%s') as hour_stamp from limpieza l ;



-- Actualizar datos fecha finish_date

start transaction;

update limpieza set finish_date = str_to_date(finish_date,'%Y-%m-%d %H:%i:%s UTC')
where finish_date <> '';

commit;

alter table limpieza 
add column fecha date,
add column hora time;



update limpieza 
set fecha = date(finish_date),
    hora = time(finish_date)
where finish_date is not null and finish_date <> '';

update limpieza set finish_date = null where finish_date ='';

alter table limpieza modify column finish_date datetime;


call lim()


-- Calculos con fechas

alter table limpieza add column age INT;

-- Edad de ingreso de los empleados

select name,birth_date ,start_date,timestampdiff(year,birth_date,start_date) as año_ingreso from limpieza l ;

-- Edad actual de los empleados
start transaction;
update limpieza set age = timestampdiff(year,birth_date,curdate()) 

commit;

select name,birth_date ,age from limpieza l ;

-- Crear un correo unico para cada empleado
select concat(substring_index(name,' ',1),'_',substring(last_name,1,2),'.',substring(type,1,1),'@gmail.com')as gmail from limpieza l; 

alter table limpieza add column email varchar(100);

-- Actualizar el campo email a la tabla
update limpieza set email = concat(substring_index(name,' ',1),'_',substring(last_name,1,2),'.',substring(type,1,1),'@gmail.com');

call lim();

-- Exportar datos necesarios para el analisis 

select id_employee,name,last_name,age,gender,area,salary,email,finish_date from limpieza l 
where finish_date <= curdate() or finish_date is null
order by area;


-- Salarios por area desde el minimo , el maximo y el promedio
select area ,min(salary) as salario_minimo,max(salary) as salario_maximo ,round(avg(salary),0) as Promedio from limpieza l group by area order by area; 

