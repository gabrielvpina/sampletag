# Uso: cd assets/icon && python3 ../../tool/generate_icon_svgs.py && ../../tool/generate_android_icons.sh
# Gera os SVGs do ícone a partir das mesmas formas (fonte única).
BG = '#3D5C40'      # verde-escuro da marca
LEAF = '#B5C08F'    # verde-sálvia claro
TAG = '#F2C230'     # amarelo da etiqueta
STRING = '#E9E4CC'
# Coordenadas em 108x108 (grade de ícone adaptativo do Android; zona segura = círculo r=33 no centro).
leaf = 'M76 32C58 28 36 40 36 68C62 72 78 52 76 32Z'
midrib = 'M39 65Q55 51 72 36'
stem = 'M37 67L31.5 72.5'
cord = 'M31.5 72.5C36 80 47 79 55.5 72.5'
tag = 'M50 72.5L56 65.5H73a2 2 0 0 1 2 2V77.5a2 2 0 0 1-2 2H56Z'
tag_tf = 'rotate(-14 62 72.5)'
hole = (56.6, 72.5, 1.9)

def fg(cut):
    return f'''<path d="{leaf}" fill="{LEAF}"/>
  <path d="{midrib}" fill="none" stroke="{cut}" stroke-width="2.6" stroke-linecap="round"/>
  <path d="{stem}" fill="none" stroke="{LEAF}" stroke-width="3" stroke-linecap="round"/>
  <path d="{cord}" fill="none" stroke="{STRING}" stroke-width="1.4" stroke-linecap="round"/>
  <g transform="{tag_tf}"><path d="{tag}" fill="{TAG}" stroke="{TAG}" stroke-width="1.5" stroke-linejoin="round"/>
  <circle cx="{hole[0]}" cy="{hole[1]}" r="{hole[2]}" fill="{cut}"/></g>'''

head = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108"'
open('sampletag_icon.svg','w').write(f'''{head} role="img" aria-label="SampleTag">
  <title>SampleTag</title>
  <rect width="108" height="108" rx="24" fill="{BG}"/>
  {fg(BG)}
</svg>
''')
open('foreground.svg','w').write(f'''{head}>
  {fg(BG)}
</svg>
''')
# Monocromático (ícones temáticos do Android 13+): uma cor, com nervura e furo vazados.
open('monochrome.svg','w').write(f'''{head}>
  <mask id="m"><rect width="108" height="108" fill="#fff"/>
    <path d="{midrib}" fill="none" stroke="#000" stroke-width="2.6" stroke-linecap="round"/>
    <g transform="{tag_tf}"><circle cx="{hole[0]}" cy="{hole[1]}" r="{hole[2]}" fill="#000"/></g></mask>
  <g mask="url(#m)" fill="#fff" stroke="#fff">
    <path d="{leaf}" stroke="none"/>
    <path d="{stem}" fill="none" stroke-width="3" stroke-linecap="round"/>
    <path d="{cord}" fill="none" stroke-width="1.4" stroke-linecap="round"/>
    <g transform="{tag_tf}"><path d="{tag}" stroke-width="1.5" stroke-linejoin="round"/></g>
  </g>
</svg>
''')
