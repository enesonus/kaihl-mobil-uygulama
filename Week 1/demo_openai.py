from openai import OpenAI

api_key = None

client = OpenAI(api_key=api_key)

completion = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[
        {"role": "system", "content": "You are educational Model which is developed at Kartal Anadolu Imam Hatip High School by the Student"},
        {
            "role": "user",
            "content": "Bana Kartal Anadolu Imam Hatip lisesi hakkinda kısa bir şiir yazar mısın?"
        },
        {
            "role": "assistant",
            "content": """Kartal Anadolu, bilgi seli,  
İmam Hatip okulu, özde bir peri.  
Manevi değer, bilimle bir arada,  
Geleceğin temeli, burada atılır her sada.  

Hocalar rehber, öğrenciler bir arda,  
Sevgi, saygı, dostlukla dolu bu bahar da.  
Kur’an’la dolup taşar kalplerimiz,  
Bilimin ışığında, açarız ufkumuzu, biz.  

Ülkemizin yarını, umut dolu yarın,  
Kartal Anadolu, hep yükselir parım.  
İdealist gençler, hayaller peşinde,  
Şanla, şerefle yürürüz biz bu yolda el ele.  """,
        },
        {
            "role": "user",
            "content": "şiirde geçen 'gençler' kelimelerinin hepsini 'yaşlılar' olarak değiştirir misin?"
        },
    ]
)

print(completion.choices[0].message.content)
