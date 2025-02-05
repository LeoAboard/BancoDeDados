--FUNÇÃO ALTURA--

CREATE OR REPLACE FUNCTION Fn_altura_m(altura int)
RETURNS numeric(6,2)
AS $$
    DECLARE altura_m numeric(6,2);
BEGIN

    altura_m = (altura::numeric(6,2) / 100)::numeric(6,2);
    RETURN altura_m;

END;
$$ LANGUAGE plpgsql;

--FUNÇÃO IMC--

CREATE OR REPLACE FUNCTION Fn_imc(peso int, altura int)
RETURNS numeric(6,2)
AS $$
    DECLARE imc numeric(6,2); altura_m numeric(6,2);
BEGIN

    altura_m = Fn_altura_m(altura);
    imc =  (peso / (altura_m * altura_m)::numeric(6,2))::numeric(6,2);

    RETURN imc;
        
END;
$$ LANGUAGE plpgsql;

--FUNÇÃO INSERE UF--

CREATE OR REPLACE FUNCTION Fn_cria_uf()
RETURNS VOID
AS $$
DECLARE i int := 1;
BEGIN

    WHILE i < 134 LOOP

        UPDATE pais
        SET estado = 'KK'||i
        WHERE id = i
        AND nome != 'BRASIL';
        i := i + 1;

    END LOOP;

END;
$$ LANGUAGE plpgsql;


--FUNÇÃO PRINCIPAL--

CREATE OR REPLACE FUNCTION Fn_cria_tabela()
RETURNS TABLE(
    id_ int,
    ano_nasc_ int,
    genero_ char,
    estado_civil_ varchar(25),
    escolaridade_ varchar(50),
    peso_kg_ int,
    altura_m_ numeric(6,2),
    imc_ numeric(6,2),
    cidade_nasc_ varchar(50),
    uf_nasc_ varchar(2),
    pais_nasc_ varchar(10),
    cidade_res_ varchar(50),
    uf_res_ varchar(2),
    pais_res_ varchar(10),
    junta_ varchar(6),
    mun_junta_ varchar(50),
    uf_junta_ varchar(2),
    pais_junta_ varchar(10),
    ano_alistamento_ int,
    situacao_ varchar(30)
)
AS $$
BEGIN

    CREATE TABLE public.individuo(
        ano_nasc int not null,
        peso int null,
        altura int null,
        cabeca int null,
        calcado int null,
        cintura int null,
        mun_nasc varchar(60) not null,
        uf_nasc varchar(5) not null,
        pais_nasc varchar(60) not null,
        estado_civil varchar(25) not null,
        genero char not null,
        escolaridade varchar(50) not null,
        ano_alistamento int not null,
        dispensa varchar(30) not null,
        zona_residencia varchar(10) not null,
        mun_residencia varchar(60) not null,
        uf_residencia varchar(5) not null,
        pais_residencia varchar(60) not null,
        junta varchar(100) not null,
        mun_junta varchar(60) not null,
        uf_junta varchar(5) not null
        );

    COPY individuo FROM
    '/tmp/sermil2023.csv' csv header delimiter ',' quote '"';

    ALTER TABLE individuo ADD COLUMN id serial not null primary key;

    UPDATE individuo
    SET pais_nasc = 'BRASIL'
    WHERE uf_nasc != 'KK';

    UPDATE individuo
    SET pais_residencia = 'BRASIL'
    WHERE uf_residencia != 'KK';

    UPDATE individuo
    SET pais_residencia = 'EXTERIOR'
    WHERE uf_residencia = 'KK' and pais_residencia = 'BRASIL';

    UPDATE individuo
    SET pais_nasc = 'EXTERIOR'
    WHERE uf_nasc = 'KK' and pais_nasc = 'BRASIL';

    --PAÍS--

    CREATE TABLE pais(
        id serial primary key,
        nome varchar(25),
        estado varchar(5)
    );

    INSERT INTO pais(nome, estado)
        SELECT DISTINCT pais_nasc, uf_nasc FROM individuo
        UNION
        SELECT DISTINCT pais_residencia, uf_residencia FROM individuo;

    PERFORM fn_cria_uf();

    UPDATE individuo
    SET uf_nasc = estado
    FROM pais
    WHERE pais_nasc != 'BRASIL'
    AND pais_nasc = pais.nome;

    UPDATE individuo
    SET uf_residencia = estado
    FROM pais
    WHERE pais_residencia != 'BRASIL'
    AND pais_residencia = pais.nome;

    UPDATE individuo
    SET uf_junta = 'KK65'
    WHERE uf_junta = 'KK';

    --UNIDADE FEDERATIVA--

    CREATE TABLE unidade_federativa(
        sigla varchar(5),
        id serial primary key
    );

    INSERT INTO unidade_federativa(sigla)
        SELECT estado FROM pais;

    ALTER TABLE unidade_federativa ADD COLUMN id_pais int;

    ALTER TABLE unidade_federativa ADD CONSTRAINT fk_pais
        FOREIGN KEY(id_pais) REFERENCES pais(id);

    UPDATE unidade_federativa
    SET id_pais = pais.id
    FROM pais
    WHERE pais.estado = unidade_federativa.sigla;

    --CIDADE--

    CREATE TABLE cidade(
        id serial primary key,
        nome varchar(50) not null,
        estado varchar(5) not null
    );

    INSERT INTO cidade(nome, estado)
        SELECT DISTINCT mun_residencia, uf_residencia FROM individuo
        UNION
        SELECT DISTINCT mun_nasc, uf_nasc FROM individuo
        UNION
        SELECT DISTINCT mun_junta, uf_junta FROM individuo;

    ALTER TABLE cidade ADD COLUMN id_uf int;

    ALTER TABLE cidade ADD CONSTRAINT fk_uf
        FOREIGN KEY(id_uf) REFERENCES unidade_federativa(id);

    UPDATE cidade
    SET id_uf = unidade_federativa.id
    FROM unidade_federativa
    WHERE cidade.estado = unidade_federativa.sigla;

    ALTER TABLE individuo ADD COLUMN id_mun_nascimento int;

    ALTER TABLE individuo ADD CONSTRAINT fk_mun_nascimento
        FOREIGN KEY(id_mun_nascimento) REFERENCES cidade(id);

    UPDATE individuo
        SET id_mun_nascimento = cidade.id
        FROM cidade
        WHERE cidade.nome = individuo.mun_nasc
        AND cidade.estado = individuo.uf_nasc;

    ALTER TABLE individuo ADD COLUMN id_mun_residencia int;
    
    ALTER TABLE individuo ADD CONSTRAINT fk_cidade_res
        FOREIGN KEY(id_mun_residencia) REFERENCES cidade(id);

    UPDATE individuo
        SET  id_mun_residencia = cidade.id
        FROM cidade
        WHERE cidade.nome = individuo.mun_residencia
        AND cidade.estado = individuo.uf_residencia;

    ALTER TABLE individuo
        DROP COLUMN mun_nasc,
        DROP COLUMN uf_nasc,
        DROP COLUMN pais_nasc,
        DROP COLUMN mun_residencia,
        DROP COLUMN uf_residencia,
        DROP COLUMN pais_residencia;

    ALTER TABLE cidade
        DROP COLUMN estado;

    ALTER TABLE pais
        DROP COLUMN estado;

    --JUNTA MILITAR--

    CREATE TABLE junta_militar(
        id serial primary key,
        junta varchar(6),
        junta_cidade varchar(50),
        uf_junta varchar(5)
    );

    UPDATE individuo
        SET junta = LEFT(junta, 6);

    INSERT INTO junta_militar(junta, junta_cidade, uf_junta)
        SELECT DISTINCT junta, mun_junta, uf_junta
        FROM individuo;

    ALTER TABLE individuo ADD COLUMN id_junta int;

    ALTER TABLE individuo ADD CONSTRAINT fk_junta
        FOREIGN KEY(id_junta) REFERENCES junta_militar(id);

    UPDATE individuo
        SET id_junta = junta_militar.id
        FROM junta_militar
        WHERE individuo.junta = junta_militar.junta;

    ALTER TABLE junta_militar ADD COLUMN id_cidade_junta int;

    ALTER TABLE junta_militar ADD CONSTRAINT fk_cidade_junta
        FOREIGN KEY(id_cidade_junta) REFERENCES cidade(id);

    UPDATE junta_militar
        SET id_cidade_junta = cidade.id
        FROM cidade
        JOIN unidade_federativa ON cidade.id_uf = unidade_federativa.id                                 
        WHERE cidade.nome = junta_militar.junta_cidade
        AND unidade_federativa.sigla = junta_militar.uf_junta;

    UPDATE junta_militar
        SET junta = TRIM(TRAILING '-' FROM TRIM(junta))
        WHERE junta LIKE '%  ' OR junta LIKE '% -' OR junta LIKE '% - ';

    ALTER TABLE junta_militar
        DROP COLUMN junta_cidade,
        DROP COLUMN uf_junta;

    ALTER TABLE individuo
        DROP COLUMN junta,
        DROP COLUMN mun_junta,
        DROP COLUMN uf_junta;

    --DADOS CORPORAIS--

    CREATE TABLE dados_corporais(
        id_individuo int null,
        peso_kg int null,
        altura_m numeric(6,2) null,
        cabeca_cm int null,
        calcado int null,
        cintura_cm int null,
        imc numeric(6,2)
    );

    INSERT INTO dados_corporais(id_individuo, peso_kg, altura_m, cabeca_cm, calcado, cintura_cm, imc)
        SELECT
        individuo.id, 
        peso,
        Fn_altura_m(altura),
        cabeca,
        calcado,
        cintura,
        Fn_imc(peso, altura)
        FROM individuo;

    ALTER TABLE dados_corporais ALTER COLUMN id_individuo SET NOT NULL;
    ALTER TABLE dados_corporais ADD CONSTRAINT pk_id_dados_corporais PRIMARY KEY (id_individuo);

    ALTER TABLE individuo ADD CONSTRAINT fk_dados_corporais
    FOREIGN KEY(id) REFERENCES dados_corporais(id_individuo);

    ALTER TABLE individuo
        DROP COLUMN peso,
        DROP COLUMN altura,
        DROP COLUMN cabeca,
        DROP COLUMN calcado,
        DROP COLUMN cintura;

    --SELECT--

    CREATE EXTENSION IF NOT EXISTS pgcrypto;

    ALTER TABLE junta_militar 
        ALTER COLUMN junta TYPE BYTEA USING pgp_sym_encrypt(junta, 'senha123');

    CREATE VIEW resumo_alistamento AS
    SELECT
    individuo.id,
    individuo.ano_nasc,
    individuo.genero,
    individuo.estado_civil,
    individuo.escolaridade,
    dados_corporais.peso_kg,
    dados_corporais.altura_m,
    dados_corporais.imc,
    cn.nome as cidade_nasc,
    ufn.sigla as uf_nasc,
    pn.nome as pais_nasc,
    cr.nome as cidade_res,
    ufr.sigla as uf_res,
    pr.nome as pais_res,
    pgp_sym_decrypt(junta_militar.junta, 'senha123')::varchar(6) as junta,
    cj.nome as mun_junta,
    ufj.sigla as uf_junta,
    pj.nome as pais_junta,
    individuo.ano_alistamento,
    individuo.dispensa as situacao
    FROM individuo
    JOIN dados_corporais ON individuo.id = dados_corporais.id_individuo
    JOIN cidade cn ON individuo.id_mun_nascimento = cn.id
    JOIN unidade_federativa ufn ON cn.id_uf = ufn.id
    JOIN pais pn ON ufn.id_pais = pn.id
    JOIN cidade cr ON individuo.id_mun_residencia = cr.id
    JOIN unidade_federativa ufr ON cr.id_uf = ufr.id
    JOIN pais pr ON ufr.id_pais = pr.id
    JOIN junta_militar ON individuo.id_junta = junta_militar.id
    JOIN cidade cj ON junta_militar.id_cidade_junta = cj.id
    JOIN unidade_federativa ufj ON cj.id_uf = ufj.id
    JOIN pais pj ON ufj.id_pais = pj.id
    WHERE pr.nome != 'BRASIL'
    LIMIT 10000;

    RETURN QUERY SELECT * FROM resumo_alistamento ORDER BY 1;
END;
$$ LANGUAGE plpgsql;

--TESTE DE DESEMPENHO--

/*CREATE OR REPLACE FUNCTION Fn_testa_desempenho()
RETURNS TEXT
AS $$
BEGIN

    CREATE TABLE teste_desempenho(
        nome varchar(30),
        estado_civil varchar(25)
        escolaridade varchar(50),
        mun_nasc varchar(50),
        mun_residencia varchar(50),
        peso_kg int,
        altura_m numeric(6,2)
    )

    EXPLAIN ANALYZE
    
END;
$$ LANGUAGE plpgsql;*/