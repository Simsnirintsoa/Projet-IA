% serveur_enquete.pl - Serveur web pour le système d'enquête
:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/html_write)).
:- use_module(library(http/http_json)).

% Configuration du serveur
:- http_handler(/, home_page, []).
:- http_handler('/api/investigate', investigate_api, [method(post)]).
:- http_handler('/api/report', report_api, []).

% Démarrer le serveur
start_server(Port) :-
    http_server(http_dispatch, [port(Port)]),
    format('Serveur démarré sur http://localhost:~w~n', [Port]).

% Page d'accueil avec l'interface
home_page(_Request) :-
    reply_html_page(
        [title('Système Expert - Enquête Policière'),
        style([type='text/css'], '
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }

            body {
                font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
                background: whitesmoke;
                min-height: 100vh;
                padding: 20px;
            }

            .container {
                max-width: 800px;
                margin: 0 auto;
                background: rgba(255, 255, 255, 0.95);
                border-radius: 15px;
                box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
                overflow: hidden;
            }

            .header {
                background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%);
                color: white;
                padding: 30px;
                  text-align: center;
            }

            .header h1 {
                font-size: 2.5em;
                margin-bottom: 10px;
                text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
            }

            .header h2 {
                font-size: 1.2em;
                opacity: 0.9;
                font-weight: 300;
            }

            .content {
                padding: 40px;
            }

            .investigation-form {
                background: #f8f9fa;
                padding: 30px;
                border-radius: 12px;
                margin-bottom: 30px;
                border-left: 5px solid #3498db;
            }.investigation-form h3 {
                color: #2c3e50;
                margin-bottom: 25px;
                font-size: 1.5em;
                display: flex;
                align-items: center;
            }

            .investigation-form h3:before {
                content: "[RECHERCHE]";
                margin-right: 10px;
            }

            .form-group {
                margin-bottom: 20px;
            }

            label {
                display: block;
                margin-bottom: 8px;
                font-weight: 600;
                color: #34495e;
            }

            select {
                width: 100%;
                padding: 12px 15px;
                border: 2px solid #ddd;
                border-radius: 8px;
                font-size: 16px;
                background-color: white;
                transition: border-color 0.3s, box-shadow 0.3s;
            }

            select:focus {
                outline: none;
                border-color: #3498db;
                box-shadow: 0 0 10px rgba(52, 152, 219, 0.2);
            }

            .submit-btn {
                background: linear-gradient(135deg, #3498db 0%, #2980b9 100%);
                color: white;
                padding: 15px 40px;
                border: none;
                border-radius: 25px;
                font-size: 18px;
                font-weight: 600;
                cursor: pointer;
                transition: all 0.3s;
                text-transform: uppercase;
                letter-spacing: 1px;
                box-shadow: 0 4px 15px rgba(52, 152, 219, 0.3);
            }

            .submit-btn:hover {
                transform: translateY(-2px);
                box-shadow: 0 6px 20px rgba(52, 152, 219, 0.4);
            }

            .submit-btn:active {
                transform: translateY(0);
              }

            .results-section {
                background: white;
                border-radius: 12px;
                padding: 30px;
                box-shadow: 0 5px 15px rgba(0, 0, 0, 0.08);
                border: 1px solid #eee;
            }

            .waiting-message {
                text-align: center;
                color: #7f8c8d;
                font-style: italic;
                padding: 40px;
            }

            .verdict-guilty {
                background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%);
                color: white;
                padding: 20px;
                border-radius: 10px;
                text-align: center;
                font-size: 1.3em;
                font-weight: bold;
                margin: 20px 0;
                text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.3);
            }

            .verdict-innocent {
                          background: linear-gradient(135deg, #27ae60 0%, #229954 100%);
                color: white;
                padding: 20px;
                border-radius: 10px;
                text-align: center;
                font-size: 1.3em;
                font-weight: bold;
                margin: 20px 0;
                text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.3);
            }

            .case-info {
                background: #ecf0f1;
                padding: 15px;
                border-radius: 8px;
                margin: 15px 0;
            }

            .case-info strong {
                color: #2c3e50;
            }

            .evidence-list {
                background: #fff3cd;
                border: 1px solid #ffeaa7;
                border-radius: 8px;
                padding: 20px;
                margin: 15px 0;
            }

            .evidence-list h4 {
                color: #856404;
                margin-bottom: 15px;
                display: flex;
                align-items: center;
            }

            .evidence-list h4:before {
                content: "[PREUVES]";
                margin-right: 8px;
            }

            .evidence-list ul {
                list-style: none;
                padding: 0;
            }

            .evidence-list li {
                padding: 8px 0;
                border-bottom: 1px solid #f1c40f;
                color: #856404;
            }

            .evidence-list li:last-child {
                border-bottom: none;
            }

            .evidence-list li:before {
                content: "- ";
                color: #3498db;
                font-weight: 600;
            }

            .loading:after {
                content: "...";
                animation: dots 1.5s infinite;
            }
           ')],

        [div([class=container], [
            div([class=header], [
                h1('Systeme Expert d\'Enquete Policiere'),
                h2('Interface d\'Investigation Criminelle')
            ]),
            
            div([class=content], [
                % Formulaire d'enquete
                div([class='investigation-form'], [
                    form([id=investigation_form], [
                        h3('Nouvelle Enquete'),
                        
                        div([class='form-group'], [
                            label([for=suspect], 'Suspect a analyser:'),
                            select([name=suspect, id=suspect], [
                                option([value=''], '-- Selectionner un suspect --'),
                                option([value=john], 'John'),
                                option([value=mary], 'Mary'),
                                option([value=alice], 'Alice'),
                                option([value=bruno], 'Bruno'),
                                option([value=sophie], 'Sophie')
                            ])
                        ]),
                        
                        div([class='form-group'], [
                            label([for=crime], 'Type de crime:'),
                            select([name=crime, id=crime], [
                                option([value=''], '-- Selectionner un crime --'),
                                option([value=vol], 'Vol qualifie'),
                                option([value=assassinat], 'Assassinat'),
                                option([value=escroquerie], 'Escroquerie')
                            ])
                        ]),
                        
                        div([class='form-group'], [
                            input([type=submit, value='Analyser le Cas', class='submit-btn'])
                        ])
                    ])
                ]),
                
                % Zone de resultats
                div([class='results-section'], [
                    div([id=results], [
                        div([class='waiting-message'], [
                            'Selectionnez un suspect et un type de crime pour commencer l\'analyse criminelle.'
                        ])
                    ])
                ])
            ])
        ]),
         % Script JavaScript
         script([type='text/javascript'], '
             document.getElementById("investigation_form").addEventListener("submit", function(e) {
                 e.preventDefault();

                 var suspect = document.getElementById("suspect").value;
                 var crime = document.getElementById("crime").value;

                 if (!suspect || !crime) {
                     alert("Veuillez sélectionner un suspect et un crime.");
                     return;
                 }

                 fetch("/api/investigate", {
                     method: "POST",
                     headers: {
                         "Content-Type": "application/json"
                     },
                     body: JSON.stringify({
                         suspect: suspect,
                         crime: crime
                     })
                 })
                 .then(response => response.json())
                 .then(data => {
                     var resultsDiv = document.getElementById("results");
                     var status = data.guilty ? "COUPABLE" : "INNOCENT";
                     var color = data.guilty ? "red" : "green";

                     var evidenceHtml = "";
                     if (data.evidence && data.evidence.length > 0) {
                         evidenceHtml = "<h4>Preuves:</h4><ul>";
                         data.evidence.forEach(function(e) {
                             evidenceHtml += "<li>" + e + "</li>";
                         });
                         evidenceHtml += "</ul>";
                     }

                     resultsDiv.innerHTML =
                         "<h3>Résultats de l\'enquête</h3>" +
                         "<p><strong>Suspect:</strong> " + data.suspect_name + "</p>" +
                         "<p><strong>Crime:</strong> " + data.crime_name + "</p>" +
                         evidenceHtml +
                         "<p style=\'color:" + color + "; font-weight:bold; font-size:1.2em\'>" +
                         "VERDICT: " + status + "</p>";
                 })
                 .catch(error => {
                     console.error("Erreur:", error);
                     document.getElementById("results").innerHTML =
                         "<p style=\'color:red\'>Erreur lors de l\'analyse.</p>";
                 });
             });
         ')
        ]).

% API pour l'investigation
investigate_api(Request) :-
    http_read_json_dict(Request, JsonIn),
    Suspect = JsonIn.suspect,
    Crime = JsonIn.crime,

    % Analyser avec notre logique Prolog
    analyze_case_web(Suspect, Crime, Result),

    reply_json_dict(Result).

% API pour le rapport
report_api(_Request) :-
    generate_report_data(ReportData),
    reply_json_dict(ReportData).

% Analyse d'un cas (version web)
analyze_case_web(Suspect, Crime, Result) :-
    atom_string(SuspectAtom, Suspect),
    atom_string(CrimeAtom, Crime),

    % Noms pour l'affichage
    suspect_name(SuspectAtom, SuspectName),
    crime_name(CrimeAtom, CrimeName),

    % Vérifier la culpabilité
    (is_guilty(SuspectAtom, CrimeAtom) ->
        Guilty = true
    ;   Guilty = false
    ),

    % Collecter les preuves
    collect_evidence(SuspectAtom, CrimeAtom, Evidence),

    Result = _{
        guilty: Guilty,
        suspect: Suspect,
        suspect_name: SuspectName,
        crime: Crime,
        crime_name: CrimeName,
        evidence: Evidence
    }.

% Collecter les preuves pour l'affichage
collect_evidence(Suspect, Crime, Evidence) :-
    findall(E, evidence_fact(Suspect, Crime, E), Evidence).

evidence_fact(Suspect, Crime, 'Motif présent') :-
    has_motive(Suspect, Crime).
evidence_fact(Suspect, Crime, 'Présent sur les lieux du crime') :-
    was_near_crime_scene(Suspect, Crime).
evidence_fact(Suspect, Crime, 'Empreintes digitales sur l\'arme') :-
    has_fingerprint_on_weapon(Suspect, Crime).
evidence_fact(Suspect, Crime, 'Transaction bancaire suspecte') :-
    has_bank_transaction(Suspect, Crime).
evidence_fact(Suspect, Crime, 'Fausse identité découverte') :-
    owns_fake_identity(Suspect, Crime).
evidence_fact(Suspect, Crime, 'Identification par témoin oculaire') :-
    eyewitness_identification(Suspect, Crime).

% Noms d'affichage
suspect_name(john, 'John Smith').
suspect_name(mary, 'Mary Johnson').
suspect_name(alice, 'Alice Brown').
suspect_name(bruno, 'Bruno Martin').
suspect_name(sophie, 'Sophie Dubois').

crime_name(vol, 'Vol qualifié').
crime_name(assassinat, 'Assassinat').
crime_name(escroquerie, 'Escroquerie').

% Générer les données du rapport
generate_report_data(ReportData) :-
    findall(Case, solved_case(Case), SolvedCases),
    length(SolvedCases, CasesAnalyzed),

    ReportData = _{
        solved_cases: SolvedCases,
        total_suspects: 5,
        total_crimes: 3,
        cases_analyzed: CasesAnalyzed
    }.

solved_case('John Smith - Vol qualifié : COUPABLE') :-
    is_guilty(john, vol).
solved_case('Mary Johnson - Assassinat : COUPABLE') :-
    is_guilty(mary, assassinat).
solved_case('Alice Brown - Escroquerie : COUPABLE') :-
    is_guilty(alice, escroquerie).

% === LOGIQUE D'ENQUÊTE ORIGINALE ===

% Types de crimes
crime_type(assassinat).
crime_type(vol).
crime_type(escroquerie).

% Suspects
suspect(john).
suspect(mary).
suspect(alice).
suspect(bruno).
suspect(sophie).

% Faits concernant le vol
has_motive(john, vol).
was_near_crime_scene(john, vol).
has_fingerprint_on_weapon(john, vol).
eyewitness_identification(john, vol).

% Faits concernant l'assassinat
has_motive(mary, assassinat).
was_near_crime_scene(mary, assassinat).
has_fingerprint_on_weapon(mary, assassinat).
eyewitness_identification(mary, assassinat).

% Faits concernant l'escroquerie
has_motive(alice, escroquerie).
has_bank_transaction(alice, escroquerie).
has_bank_transaction(bruno, escroquerie).
owns_fake_identity(sophie, escroquerie).

% Règles de culpabilité
is_guilty(Suspect, vol) :-
    has_motive(Suspect, vol),
    was_near_crime_scene(Suspect, vol),
    (has_fingerprint_on_weapon(Suspect, vol)
    ; eyewitness_identification(Suspect, vol)
    ).

is_guilty(Suspect, assassinat) :-
    has_motive(Suspect, assassinat),
    was_near_crime_scene(Suspect, assassinat),
    (has_fingerprint_on_weapon(Suspect, assassinat)
    ; eyewitness_identification(Suspect, assassinat)
    ).

is_guilty(Suspect, escroquerie) :-
    (has_bank_transaction(Suspect, escroquerie)
    ; owns_fake_identity(Suspect, escroquerie)
    ),
    has_motive(Suspect, escroquerie).

% Point d'entrée principal
start :-
    write('Démarrage du serveur web...'), nl,
    start_server(8080),
    write('Serveur prêt ! Ouvrez http://localhost:8080 dans votre navigateur'), nl,
    write('Appuyez sur Ctrl+C pour arrêter le serveur.'), nl.
