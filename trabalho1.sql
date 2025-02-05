CREATE TABLE public.estagio(
    id int not null primary key,
    vinculo varchar(10) not null,
    data_inicio varchar(20) not null,
    estudante_nome varchar(100) not null,
    matricula varchar(60) not null,
    obrigatorio varchar(3) not null,
    data_diploma varchar(20) null,
    percentual_disciplinas varchar(60) null,
    curso varchar(150) not null,
    curso_estrutura varchar(150) not null,
    curso_modalidade varchar(60) not null,
    periodo_min_obg varchar(10) null,
    periodo_min_nao_obg varchar(10) null,
    campus varchar(3) not null,
    concedente_nome varchar(150) not null,
    concedente_cnpj varchar(60) null,
    concedente_endereco varchar(200) null,
    concedente_bairro varchar(60) null,
    concedente_cidade varchar(60) null,
    supervisor_nome varchar(200) null,
    supervisor_email varchar(60) null,
    supervisor_telefone varchar(60) null,
    orientador_nome varchar(60) not null,
    orientador_matricula int not null,
    orientador_email varchar(60) null,
    agente_nome varchar(150) null,
    agente_cnpj varchar(60) null,
    data_fim_previsto varchar(20) not null,
    seguradora_nome varchar(150) not null,
    seguradora_id varchar(150) null,
    statu varchar(60) not null,
    visitas_realizadads int null,
    visitas_justificadas int null,
    visitas_vencer int null,
    visitas_nao_realizadas int null,
    pendencias varchar(1000) null,
    data_fim varchar(60) null,
    aditivo varchar(60) null,
    aditivo_tipo varchar(150) null,
    encerramento varchar(60) null,
    encerramento_motivo varchar(1000) null,
    recisao_motivo varchar(5000) null,
    notas_media varchar(10) null,
    CH_final varchar(10) null,
    sera_contratado varchar(3) null
);

COPY estagio FROM
    '/tmp/estagio.csv' csv header delimiter ',' quote '"';        --LEMBRAR DE ALTERAR O CAMINHO DA PASTA DO CSV--

SELECT * INTO Estudante from estagio;

DROP TABLE estagio;

ALTER TABLE Estudante ADD CONSTRAINT PK_Estudante PRIMARY KEY (id);

/*Orientador*/

CREATE TABLE Orientador(
    id serial not null primary key,
    nome varchar(60) not null,
    matricula int not null,
    email varchar(60) null
);

INSERT INTO Orientador(nome, matricula, email)
    SELECT DISTINCT orientador_nome, orientador_matricula, orientador_email
    FROM Estudante
    ORDER BY orientador_nome;

ALTER TABLE Estudante ADD COLUMN Orientador_id int;

ALTER TABLE Estudante ADD CONSTRAINT fk_orientador
    FOREIGN KEY(Orientador_id) REFERENCES Orientador(id);

UPDATE Estudante
    SET orientador_id = (
    SELECT id
    FROM Orientador
    WHERE Orientador.matricula = Estudante.orientador_matricula
);

ALTER TABLE Estudante
    DROP COLUMN orientador_nome,
    DROP COLUMN orientador_matricula,
    DROP COLUMN orientador_email;

/*Curso*/

CREATE TABLE Curso(
    id serial not null primary key,
    nome varchar(150) not null,
    estrutura varchar(150) not null,
    modalidade varchar(150) not null
);

INSERT INTO Curso(nome, estrutura, modalidade)
    SELECT DISTINCT curso, curso_estrutura, curso_modalidade
    FROM Estudante
    ORDER BY curso;

ALTER TABLE Estudante ADD COLUMN Curso_id int;

ALTER TABLE Estudante ADD CONSTRAINT fk_curso
    FOREIGN KEY(Curso_id) REFERENCES Curso(id);

UPDATE Estudante
    SET Curso_id = (
    SELECT id
    FROM Curso
    WHERE Curso.nome = Estudante.curso
    AND Curso.estrutura = Estudante.curso_estrutura
    AND Curso.modalidade = Estudante.curso_modalidade
);

ALTER TABLE Estudante
    DROP COLUMN curso,
    DROP COLUMN curso_estrutura,
    DROP COLUMN curso_modalidade;

/*Estagio*/

CREATE TABLE Estagio(
    id serial primary key not null,
    data_inicio varchar(20) not null,
    data_fim_previsto varchar(20) not null,
    data_fim varchar(20) null,
    seguradora varchar(150) not null,
    situacao varchar(60) not null,
    pendencias varchar(200) null,
    estudante varchar(100) not null
);

INSERT INTO Estagio(data_inicio, data_fim_previsto, data_fim, seguradora, situacao, pendencias, estudante)
    SELECT data_inicio, data_fim_previsto, data_fim, seguradora_nome, statu, pendencias, estudante_nome
    FROM Estudante
    ORDER BY seguradora_nome;

ALTER TABLE Estudante ADD COLUMN estagio_id int;

ALTER TABLE Estudante ADD CONSTRAINT fk_estagio
    FOREIGN KEY(estagio_id) REFERENCES Estagio(id);   

UPDATE Estudante SET estagio_id = estagio.id
    FROM Estagio
    WHERE estudante.estudante_nome = estagio.estudante;  

ALTER TABLE Estagio
    DROP COLUMN Estudante;

ALTER TABLE Estudante
    DROP COLUMN data_inicio,
    DROP COLUMN data_fim,
    DROP COLUMN data_fim_previsto,
    DROP COLUMN pendencias,
    DROP COLUMN statu,
    DROP COLUMN seguradora_nome;

/*Concedente*/

CREATE TABLE Concedente(
    id serial primary key not null,
    nome varchar(150) not null,
    cnpj varchar(60) null,
    rua varchar(200) null,
    bairro varchar(60) null,
    cidade varchar(60) null
);

INSERT INTO Concedente(nome, cnpj, rua, bairro, cidade)
    SELECT DISTINCT concedente_nome, concedente_cnpj, concedente_endereco, concedente_bairro, concedente_cidade
    FROM Estudante
    ORDER BY concedente_nome;

ALTER TABLE Estagio ADD COLUMN concedente_id int;

ALTER TABLE Estagio ADD CONSTRAINT fk_concedente
    FOREIGN KEY(concedente_id) REFERENCES Concedente(id);

UPDATE Estagio SET concedente_id = concedente.id
    FROM Concedente
    JOIN Estudante ON concedente_nome = concedente.nome
    WHERE estagio_id = Estagio.id;

ALTER TABLE Estudante
    DROP COLUMN concedente_nome,
    DROP COLUMN concedente_cnpj,
    DROP COLUMN concedente_endereco,
    DROP COLUMN concedente_bairro,
    DROP COLUMN concedente_cidade;

/*Supervisor*/

CREATE TABLE Supervisor(
    id serial primary key not null,
    nome varchar(200) null,
    email varchar(60) null,
    telefone varchar(60) null
);

INSERT INTO Supervisor(nome, email, telefone)
    SELECT DISTINCT supervisor_nome, supervisor_email, supervisor_telefone
    FROM Estudante
    ORDER BY supervisor_nome;

ALTER TABLE Estagio ADD COLUMN supervisor_id int;

ALTER TABLE Estagio ADD CONSTRAINT fk_supervisor
    FOREIGN KEY(supervisor_id) REFERENCES supervisor(id);

UPDATE Estagio SET supervisor_id = supervisor.id
    FROM Supervisor
    JOIN Estudante ON supervisor_nome = supervisor.nome
    WHERE estagio_id = Estagio.id;

/*Estudante*/

ALTER TABLE Estudante
    DROP COLUMN supervisor_nome,
    DROP COLUMN supervisor_email,
    DROP COLUMN supervisor_telefone,
    DROP COLUMN agente_nome,
    DROP COLUMN agente_cnpj,
    DROP COLUMN aditivo,
    DROP COLUMN aditivo_tipo,
    DROP COLUMN encerramento,
    DROP COLUMN encerramento_motivo,
    DROP COLUMN recisao_motivo,
    DROP COLUMN visitas_realizadads,
    DROP COLUMN visitas_nao_realizadas,
    DROP COLUMN visitas_justificadas,
    DROP COLUMN visitas_vencer,
    DROP COLUMN periodo_min_obg,
    DROP COLUMN periodo_min_nao_obg,
    DROP COLUMN percentual_disciplinas,
    DROP COLUMN obrigatorio,
    DROP COLUMN sera_contratado,
    DROP COLUMN CH_final,
    DROP COLUMN notas_media,
    DROP COLUMN seguradora_id;

ALTER TABLE Estudante RENAME COLUMN estudante_nome TO nome;
ALTER TABLE Estudante RENAME COLUMN data_diploma to data_formatura;
ALTER TABLE Estudante ADD COLUMN matricula_codigo VARCHAR(11);

UPDATE Estudante
SET matricula_codigo = RIGHT(nome, 11);

UPDATE Estudante
SET nome = LEFT(nome, LENGTH(nome) - 11);

/*Select*/

\x

SELECT DISTINCT Estudante.nome AS "Estudante", Estudante.campus AS "Campus", Curso.nome AS "Curso", Curso.estrutura AS "Curso tipo", Orientador.nome AS "Orientador", Orientador.email AS "Orientador email", Estudante.vinculo AS "Vinculo", Estagio.data_inicio AS "Estágio inicio", Estagio.situacao AS "Situação", Concedente.nome AS "Concedente", Supervisor.nome AS "Supervisor", Supervisor.email AS "Supervisor email"
    FROM Estudante
    JOIN Orientador ON Estudante.Orientador_id = Orientador.id
    JOIN Curso ON Estudante.Curso_id = Curso.id
    JOIN Estagio ON Estudante.estagio_id = Estagio.id
    JOIN Concedente ON Estagio.concedente_id = Concedente.id
    JOIN Supervisor ON Estagio.supervisor_id = Supervisor.id
    ORDER BY Estudante.nome, Curso.nome;

/*resumo tabelas*/

SELECT 'Estudante' AS tabela, COUNT(*) AS quantidade FROM Estudante
UNION ALL
SELECT 'Curso' AS tabela, COUNT(*) AS quantidade FROM Curso
UNION ALL
SELECT 'Orientador' AS tabela, COUNT(*) AS quantidade FROM Orientador
UNION ALL
SELECT 'Estagio' AS tabela, COUNT(*) AS quantidade FROM Estagio
UNION ALL
SELECT 'Supervisor' AS tabela, COUNT(*) AS quantidade FROM Supervisor
UNION ALL
SELECT 'Concedente' AS tabela, COUNT(*) AS quantidade FROM Concedente;