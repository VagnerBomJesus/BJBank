# BJBank - Criptografia Pós-Quântica em Aplicações Móveis

[![Flutter](https://img.shields.io/badge/Flutter-3.8.1-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.8.1-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Academic-green.svg)]()

## Sobre o Projeto

O **BJBank** é um protótipo de aplicação móvel de homebanking desenvolvido como prova de conceito para investigação e implementação de protocolos de **Criptografia Pós-Quântica (PQC)** em ambiente móvel clássico.

Este projeto faz parte da dissertação de Mestrado intitulada:

> **"Criptografia Pós-Quântica em Aplicações Móveis"**

### Autor
**Vagner Bom Jesus**

### Orientador
**Professor Rui A. P. Perdigão**

### Instituição
**Instituto Politécnico da Guarda**

---

## Contexto e Motivação

Com o crescimento da complexidade e criticidade das infraestruturas digitais, novos métodos de proteção são necessários para mitigar proativamente as vulnerabilidades de segurança decorrentes da evolução tecnológica.

Tradicionalmente, a proteção das transações dos ecossistemas e infraestruturas de informação e comunicação (e.g., homebanking) depende de mecanismos criptográficos clássicos, o que as torna **vulneráveis à ameaça iminente de ataques com recurso a tecnologias quânticas**.

Este projeto propõe investigar e explorar as potencialidades de sistemas emergentes de **Criptografia Pós-Quântica (PQC)** como mecanismo potenciador de proteção de longo prazo para aplicações móveis, mesmo em ambiente clássico.

### Hipótese de Trabalho

Alterações no paradigma da computação, como o surgimento de ataques alavancados por tecnologias quânticas, exigem que o sistema de segurança do modelo homebanking se adapte e implemente um **protocolo quântico resistente (quantum-resistant protocol)**.

---

## Objetivos

### Objetivo Central
Desenvolvimento, implementação e validação de um protocolo PQC resiliente em um ambiente móvel simulado.

### Objetivos Específicos

1. **Análise de Vulnerabilidades** - Analisar as vulnerabilidades de segurança das aplicações móveis como homebanking em relação a ataques oriundos de agentes munidos de tecnologias quânticas.

2. **Investigação e Seleção de Protocolos** - Investigar e selecionar protocolos e algoritmos de Criptografia Pós-Quântica (PQC) mais adequados para o ambiente restrito de plataformas móveis.

3. **Implementação de Protótipo** - Propor e implementar um protótipo de um protocolo PQC selecionado num caso de estudo simulado de "homebanking" em ambiente móvel clássico.

4. **Avaliação de Risco Comparativa** - Realizar uma Avaliação de Risco comparativa do sistema com criptografia clássica vs. munido de PQC, quantificando o impacto da transição na segurança ("Avaliação Antes e Depois da implementação da solução Pós-Quântica").

5. **Avaliação de Viabilidade** - Avaliar a viabilidade prática dos algoritmos PQC em plataformas móveis clássicas.

---

## Metodologia

A metodologia proposta combina investigação teórica, desenvolvimento prático e avaliação quantitativa, seguindo as seguintes etapas:

### 1. Fundamentos Teórico-Metodológicos
- Revisão crítica da literatura sobre Segurança Quântica
- Identificação de ameaças quânticas
- Definição do caso de estudo de "Homebanking"
- Elaboração da Avaliação de Risco Pré-PQC

### 2. Desenvolvimento Científico em Criptografia Pós-Quântica
- Estudo e seleção dos algoritmos PQC
- Otimização teórica para o ambiente móvel
- Definição da Avaliação de Risco Pós-PQC

### 3. Implementação Técnico-Científica
- Desenvolvimento de um protótipo de aplicativo móvel (prova de conceito em ambiente de software clássico)
- Codificação e integração do protocolo PQC selecionado

### 4. Análise e Discussão dos Resultados
- Testes de desempenho no dispositivo móvel
- Medição e avaliação de métricas (latência, throughput, tamanho das chaves/assinaturas)
- Validação dos resultados da Análise de Risco
- Conclusões e perspetivas

### 5. Documentação
- Apresentação e discussão de resultados de forma clara e estruturada
- Redação da dissertação e demais produção académico-científica relevante

---

## Plano de Trabalho

| Tarefa | Descrição |
|--------|-----------|
| **T1** | Revisão do Estado da Arte e Enquadramento Científico - Revisão sobre vulnerabilidade e sistemas, criptografia quântica (QKD) vs. Pós-Quântica (PQC), e Avaliação de Risco (Clássico) |
| **T2** | Desenvolvimento Científico - Seleção, estudo e otimização do protocolo PQC (quantum-resistant protocol) para dispositivos móveis |
| **T3** | Implementação Técnico-Científica - Desenvolvimento do aplicativo móvel (protótipo) e implementação do protocolo quântico no módulo de comunicação |
| **T4** | Análise e Discussão - Análise do impacto e Validação dos resultados; fiabilidade do PQC em plataforma móvel |
| **T5** | Escrita da Dissertação - Redação do relatório técnico e científico, Preparação de artigo para apresentação em conferência ou workshop académico |

---

## Stack Tecnológica

- **Framework**: Flutter 3.8.1
- **Linguagem**: Dart
- **Plataformas Alvo**: Android, iOS, Windows
- **Linting**: flutter_lints ^5.0.0

## Estrutura do Projeto

```
bjbank/
├── lib/                    # Código-fonte Dart
│   └── main.dart          # Ponto de entrada da aplicação
├── test/                   # Testes unitários e de widget
├── android/                # Configurações Android
├── ios/                    # Configurações iOS
├── windows/                # Configurações Windows
├── pubspec.yaml           # Dependências do projeto
├── analysis_options.yaml  # Configurações de linting
├── CLAUDE.md              # Instruções para desenvolvimento
└── README.md              # Este ficheiro
```

## Comandos de Desenvolvimento

```bash
# Instalar dependências
flutter pub get

# Executar a aplicação
flutter run

# Executar testes
flutter test

# Analisar código
flutter analyze

# Build para produção
flutter build apk        # Android
flutter build ios        # iOS
flutter build windows    # Windows
```

---

## Referências Bibliográficas

1. Perdigão, Rui A.P. (2024): *From Quantum Information to Post-Quantum Security*. DOI: 10.46337/uc.241019.

2. Cohen-Tannoudji, C., Diu, B., & Laloë, F. (2020): *Quantum Mechanics, Volume I: Basic Concepts, Tools, and Applications* (2nd Edition). Wiley.

3. Nielsen, M., & Chuang, I. (2010): *Quantum Computation and Quantum Information*. Cambridge University Press.

4. Bernstein, D.J., Buchmann, J., & Dahmen, E. (2009): *Post-Quantum Cryptography*. Springer Berlin.

5. Barnett, S. (2009): *Quantum Information* (Vol. 16). Oxford University Press.

6. Kaye, P., Laflamme, R., & Mosca, M. (2007): *An Introduction to Quantum Computing*. Oxford University Press.

7. Watrous, J. (2018): *The Theory of Quantum Information*. Cambridge University Press.

8. Kitaev, A.V., Shen, A.H., & Vyalyi, M.N. (2002): *Classical and Quantum Computation* (Graduate Studies in Mathematics). American Mathematical Society.

---

## Viabilidade do Projeto

O plano de trabalho apresentado revela viabilidade científica e técnica:

- **Enquadramento adequado** em termos de objetivos e metodologia
- **Ambição académica** contribuindo para a temática da Cibersegurança Pós-Quântica
- **Relevância prática** em investigação, desenvolvimento e inovação tecnológica
- **Pertinência e atualidade** com potencial de impacto dentro e fora do contexto académico
- **Potencial multissetorial** podendo contribuir para a emergência de novos produtos e serviços no âmbito da Cibersegurança Pós-Quântica

---

## Licença

Este projeto é desenvolvido no âmbito académico do Instituto Politécnico da Guarda.

---

## Contacto

**Autor**: Vagner Bom Jesus
**Orientador**: Professor Rui A. P. Perdigão
**Instituição**: Instituto Politécnico da Guarda

---

<p align="center">
  <i>Dissertação de Mestrado - Instituto Politécnico da Guarda</i>
</p>
