{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "250346cb320d68211881ea973a1fc30cb1589affe0eed76e8a4d3e3d69287371",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3657[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[39];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1498 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1505;\n    if (!_1498)\n    {\n        _1505 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1505 = _1498;\n    }\n    bool _1513;\n    if (!_1505)\n    {\n        _1513 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1513 = _1505;\n    }\n    bool _1520;\n    if (!_1513)\n    {\n        _1520 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1520 = _1513;\n    }\n    bool _1527;\n    if (!_1520)\n    {\n        _1527 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1527 = _1520;\n    }\n    if (_1527)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1537 = vec4(world_pos, 1.0);\n    float _1543 = dot(fa_mesh_fs_params[16], _1537);\n    if (!(_1543 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1565 = vec2(dot(fa_mesh_fs_params[14], _1537), dot(fa_mesh_fs_params[15], _1537)) / vec2(_1543);\n    int _1569 = int(fa_mesh_fs_params[18].x);\n    int _1573 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1573) + clamp(int(floor(((_1565.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1573 - 1)) * _1569)) + clamp(int(floor(((_1565.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1569 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1649 = fa_cluster_texel(param);\n    return ivec2(int(_1649.x), int(_1649.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4755 = fa_cluster_lookup(param);\n    fa_cl_slot = _4755.x;\n    fa_cl_local = _4755.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5899 = fa_linear_to_srgb(param);\n        c = _5899;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5907 = fa_srgb_to_linear(param_1);\n            c = _5907;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _442;\n    if (i.front_facing)\n    {\n        _442 = i.world_normal;\n    }\n    else\n    {\n        _442 = -i.world_normal;\n    }\n    vec3 _466 = normalize(i.world_tangent.xyz - (_442 * dot(_442, i.world_tangent.xyz)));\n    vec3 _493 = normalize(((_466 * m.x) + ((cross(_442, _466) * i.world_tangent.w) * m.y)) + (_442 * m.z));\n    vec3 _496;\n    if (i.front_facing)\n    {\n        _496 = _493;\n    }\n    else\n    {\n        _496 = -_493;\n    }\n    return _496;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5938 = fa_tex_fix(param_2, param_3);\n    vec4 _7398 = base_t;\n    _7398.x = _5938.x;\n    _7398.y = _5938.y;\n    _7398.z = _5938.z;\n    base_t = _7398;\n    vec4 _5952 = (_7398 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _7223 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5984 = fa_tex_fix(param_6, param_7);\n        vec3 _5987 = (_5984 * 2.0) - vec3(1.0);\n        vec2 _5992 = _5987.xy * fa_mesh_fs_params[6].x;\n        vec3 _7406 = _5987;\n        _7406.x = _5992.x;\n        _7406.y = _5992.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7406;\n        _7223 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _6020 = fa_tex_fix(param_12, param_13);\n    vec4 _7409 = mrt;\n    _7409.x = _6020.x;\n    _7409.y = _6020.y;\n    _7409.z = _6020.z;\n    mrt = _7409;\n    vec4 _6048 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _6048.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _6059 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _6089 = fa_tex_fix(param_20, param_21);\n    float _7228 = fa_mesh_fs_params[20].x;\n    float _7229 = fa_mesh_fs_params[20].y;\n    float _7232 = fa_mesh_fs_params[20].z;\n    float _7231 = fa_mesh_fs_params[21].w;\n    float _7234 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _7228 *= _6059.y;\n            _7229 *= _6059.z;\n            _7231 *= _6048.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _7232 *= mrt.x;\n            _7234 *= mrt.w;\n        }\n    }\n    return Surface(_5952.xyz, _5952.w, _7223, clamp(fa_mesh_fs_params[5].x * _6020.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _6020.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_6059.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _6089), _7228, _7229, fa_mesh_fs_params[21].xyz, _7231, _7232, fa_mesh_fs_params[20].w, _7234, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += vec3(0.5 + (0.5 * sin(fa_mesh_fs_params[13].x * 3.0)), 0.25 * fract(fa_mesh_fs_params[13].x), 0.0);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1729 = rect.zw - rect.xy;\n    vec2 _1733 = _1729 * atlas;\n    vec2 _1737 = ddx * _1733;\n    vec2 _1741 = ddy * _1733;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1729), clamp(0.5 * log2(max(max(dot(_1737, _1737), dot(_1741, _1741)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1774 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1781;\n    if (!_1774)\n    {\n        _1781 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1781 = _1774;\n    }\n    if (_1781)\n    {\n        return;\n    }\n    vec3 _1787 = dFdx(world_pos);\n    vec3 _1790 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1794 = fa_cluster_texel(param);\n    int _1798 = int(_1794.w);\n    if (_1798 < 1)\n    {\n        return;\n    }\n    int _1808 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1808;\n    vec4 _1812 = fa_light_texel(param_1);\n    vec2 _1815 = _1812.yz;\n    int _1819 = int(_1812.w);\n    int param_2 = _1808 + 1;\n    vec4 _1824 = fa_light_texel(param_2);\n    float _1825 = _1824.x;\n    int _1831 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1835 = int(_1794.z);\n    vec3 _2100;\n    for (int k = 0; k < _1798; k++)\n    {\n        int _1848 = _1835 + k;\n        int param_3 = _1819 + (_1848 >> 2);\n        int _1865 = (_1808 + 2) + (int(fa_light_texel(param_3)[_1848 & 3]) * 7);\n        int param_4 = _1865 + 6;\n        vec4 _1870 = fa_light_texel(param_4);\n        if (((int(_1870.w + 0.5) >> _1831) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1865;\n        vec4 _1885 = fa_light_texel(param_5);\n        int param_6 = _1865 + 1;\n        vec4 _1890 = fa_light_texel(param_6);\n        int param_7 = _1865 + 2;\n        vec4 _1895 = fa_light_texel(param_7);\n        vec3 _1898 = _1885.xyz;\n        float _1903 = dot(_1898, world_pos) + _1885.w;\n        vec3 _1905 = _1890.xyz;\n        float _1910 = dot(_1905, world_pos) + _1890.w;\n        vec3 _1912 = _1895.xyz;\n        float _1917 = dot(_1912, world_pos) + _1895.w;\n        bool _1922 = abs(_1903) > 0.5;\n        bool _1930;\n        if (!_1922)\n        {\n            _1930 = abs(_1910) > 0.5;\n        }\n        else\n        {\n            _1930 = _1922;\n        }\n        bool _1938;\n        if (!_1930)\n        {\n            _1938 = abs(_1917) > 0.5;\n        }\n        else\n        {\n            _1938 = _1930;\n        }\n        if (_1938)\n        {\n            continue;\n        }\n        float _1953 = clamp(dot(geo_normal, normalize(_1912)) * _1870.z, 0.0, 1.0);\n        if (_1953 <= 0.0)\n        {\n            continue;\n        }\n        float _1973 = (clamp((0.5 - abs(_1917)) * 10.0, 0.0, 1.0) * _1953) * _1870.x;\n        vec2 _1981 = vec2(_1903 + 0.5, 0.5 - _1910);\n        vec2 _1991 = vec2(dot(_1898, _1787), dot(_1905, _1787));\n        vec2 _2001 = vec2(dot(_1898, _1790), dot(_1905, _1790));\n        int param_8 = _1865 + 5;\n        vec4 _2006 = fa_light_texel(param_8);\n        int param_9 = _1865 + 3;\n        vec4 _2011 = fa_light_texel(param_9);\n        int param_10 = _1865 + 4;\n        vec4 _2016 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2006.xyz;\n        bool _2026 = _2011.z > _2011.x;\n        if (_2026)\n        {\n            vec4 param_11 = _2011;\n            vec2 param_12 = _1981;\n            vec2 param_13 = _1815;\n            vec2 param_14 = _1991;\n            vec2 param_15 = _2001;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1825 > 0.5) && (_1825 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2052 = fa_dc_to_linear(param_16);\n                vec4 _7303 = tx;\n                _7303.x = _2052.x;\n                _7303.y = _2052.y;\n                _7303.z = _2052.z;\n                tx = _7303;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1973 * tex_a) * _2006.w, 0.0, 1.0)));\n        if (_2016.z > _2016.x)\n        {\n            vec4 param_17 = _2016;\n            vec2 param_18 = _1981;\n            vec2 param_19 = _1815;\n            vec2 param_20 = _1991;\n            vec2 param_21 = _2001;\n            vec4 _2096 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1825 > 1.5)\n            {\n                vec3 param_22 = _2096.xyz;\n                vec3 _2106 = fa_dc_to_srgb(param_22);\n                _2100 = _2106;\n            }\n            else\n            {\n                _2100 = _2096.xyz;\n            }\n            vec3 _2115 = (_2100 * 2.0) - vec3(1.0);\n            vec2 _2120 = _2115.xy * _1870.y;\n            vec3 _2142 = (normalize(_1898) * _2120.x) + (normalize(_1905) * _2120.y);\n            vec3 _2145 = normalize(normal);\n            normal = normalize(mix(_2145, normalize((_2145 * max(_2115.z, 0.0500000007450580596923828125)) + (_2142 - (_2145 * dot(_2145, _2142)))), vec3(clamp(_1973 * (_2026 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3583 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3590 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3593 = int(_3583);\n    int _3596 = int(_3590);\n    float _3606 = _3590 - float(_3596);\n    int _3661 = (_3593 * 9) + _3596;\n    int _3681 = ((_3593 + 1) * 9) + _3596;\n    return mix(mix(_3657[_3661], _3657[_3661 + 1], _3606), mix(_3657[_3681], _3657[_3681 + 1], _3606), _3583 - float(_3593));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _7146 = false;\n    float _7147 = 1.0;\n    float _7148 = 1.0;\n    float _7149 = 1.0;\n    float _7150 = 0.0;\n    float _7151 = 0.0;\n    float _7152 = 0.0;\n    float _7153 = 0.0;\n    float _7155 = 1.0;\n    bool _7156 = false;\n    vec3 _7157 = vec3(0.0);\n    float _7158 = 1.0;\n    float _7159 = 1.0;\n    float _7160 = 1.0;\n    float _7161 = 0.0;\n    float _7162 = 0.0;\n    vec3 _7163 = vec3(1.0, 0.0, 0.0);\n    vec3 _7164 = vec3(0.0, 0.0, 1.0);\n    float _7165 = 1.0;\n    float _7166 = 1.0;\n    float _3732 = clamp(s.specular, 0.0, 1.0);\n    float _3736 = clamp(s.ior, 1.0, 3.0);\n    bool _3741 = (_3732 != 1.0) || (_3736 != 1.5);\n    bool _3750;\n    if (!_3741)\n    {\n        _3750 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3750 = _3741;\n    }\n    if (_3750)\n    {\n        float _3758 = (_3736 - 1.0) / (_3736 + 1.0);\n        f0 = mix(min(vec3(_3758 * _3758) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3732, s.albedo, vec3(metallic));\n        _7147 = mix(_3732, 1.0, metallic);\n        _7146 = true;\n    }\n    float _3785 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3785 > 0.0)\n    {\n        float _3793 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _7150 = _3785;\n        _7151 = _3793;\n        float _3800 = _3793 * _3793;\n        _7152 = _3800;\n        _7153 = _3800 * _3800;\n        float _3812 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _7155 = _3812;\n        _7148 = 1.0 - (_3785 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3812, 0.0, 1.0), 5.0))));\n        _7146 = true;\n    }\n    vec3 _3831 = max(s.sheen_color, vec3(0.0));\n    float _3840 = max(_3831.x, max(_3831.y, _3831.z));\n    if (_3840 > 0.0)\n    {\n        float _3848 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _7156 = true;\n        _7157 = _3831;\n        _7158 = _3848;\n        _7159 = _3848 * _3848;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3848;\n        float _3865 = fa_sheen_albedo(param, param_1);\n        _7161 = _3865;\n        _7160 = 1.0 - min(_3840 * _3865, 1.0);\n        _7146 = true;\n    }\n    _7149 = _7148 * _7160;\n    float _3884 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3884 != 0.0)\n    {\n        vec3 _3899 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3899;\n        if (dot(_3899, _3899) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3911 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3911.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3911.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3911.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3915 = t;\n        vec3 _3916 = normalize(_3915);\n        t = _3916;\n        vec3 _3941 = normalize((_3916 * cos(s.anisotropy_rotation)) + ((cross(n, _3916) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _7163 = _3941;\n        _7164 = cross(n, _3941);\n        float _3951 = roughness * roughness;\n        float _3957 = mix(_3951, 1.0, _3884 * _3884);\n        bool _3959 = _3884 > 0.0;\n        _7165 = _3959 ? _3957 : _3951;\n        _7166 = _3959 ? _3951 : _3957;\n        _7162 = _3884;\n        _7146 = true;\n    }\n    return FaLayers(_7146, _7147, _7148, _7149, _7150, _7151, _7152, _7153, i.world_normal, _7155, _7156, _7157, _7158, _7159, _7160, _7161, _7162, _7163, _7164, _7165, _7166);\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3340 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3340;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[30].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 30].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[30].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4725;\n    if (fa_lm.z > 0.5)\n    {\n        _4725 = 0.0;\n    }\n    else\n    {\n        _4725 = 1.0 - clamp(fa_mesh_fs_params[30].w, 0.0, 1.0);\n    }\n    bool _4736 = _4725 < 1.0;\n    bool _4742;\n    if (_4736)\n    {\n        int param = li;\n        _4742 = fa_light_baked(param);\n    }\n    else\n    {\n        _4742 = _4736;\n    }\n    return _4742 ? _4725 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _747 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _760 = (c - (ru * hx)) - p;\n        vec3 _766 = ru * (2.0 * hx);\n        float _772 = max(dot(_766, _766), 9.9999999392252902907785028219223e-09);\n        float _776 = dot(_760, _766);\n        float t = clamp((-_776) / _772, 0.0, 1.0);\n        if (_747)\n        {\n            float _791 = dot(r, _766);\n            float _797 = _772 - (_791 * _791);\n            if (abs(_797) > (9.9999997473787516355514526367188e-06 * _772))\n            {\n                t = clamp(((dot(r, _760) * _791) - _776) / _797, 0.0, 1.0);\n            }\n        }\n        return (p + _760) + (_766 * t);\n    }\n    vec3 q = p;\n    float _829 = dot(r, axis);\n    bool _837;\n    if (_747)\n    {\n        _837 = abs(_829) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _837 = _747;\n    }\n    if (_837)\n    {\n        float _847 = dot(c - p, axis) / _829;\n        if (_847 > 0.0)\n        {\n            q = p + (r * _847);\n        }\n    }\n    vec3 _860 = q - c;\n    vec2 xy = vec2(dot(_860, ru), dot(_860, uu));\n    if (shape > 0.5)\n    {\n        float _875 = length(xy);\n        if (_875 > hx)\n        {\n            xy *= (hx / _875);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _508 = abs(d);\n    float _510 = _508.x;\n    float _512 = _508.y;\n    bool _513 = _510 >= _512;\n    bool _521;\n    if (_513)\n    {\n        _521 = _510 >= _508.z;\n    }\n    else\n    {\n        _521 = _513;\n    }\n    int _522;\n    if (_521)\n    {\n        _522 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _537;\n        if (_512 >= _508.z)\n        {\n            _537 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _537 = (d.z > 0.0) ? 4 : 5;\n        }\n        _522 = _537;\n    }\n    return _522;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _667 = dot(d, right);\n    float _671 = dot(d, up);\n    float _682;\n    if (((_667 * _667) + (_671 * _671)) > 1.0000000133514319600180897396058e-10)\n    {\n        _682 = atan(_671, _667) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _682 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_682 - floor(_682)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _913 = fa_light_base(param);\n    bool _917 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _913;\n    vec4 _921 = fa_light_texel(param_1);\n    int param_2 = _913 + 1;\n    vec4 _926 = fa_light_texel(param_2);\n    float _929 = _926.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _941 = _917 && (_929 > 2.5);\n    fa_light_is_area = _941;\n    bool _943 = _929 < 0.5;\n    vec3 l;\n    if (_943)\n    {\n        l = normalize(_921.xyz);\n        if (_917)\n        {\n            int param_3 = _913 + 6;\n            vec4 _957 = fa_light_texel(param_3);\n            if (_957.z > 0.5)\n            {\n                int param_4 = _913 + 4;\n                vec4 _967 = fa_light_texel(param_4);\n                int param_5 = _913 + 5;\n                vec4 _972 = fa_light_texel(param_5);\n                vec2 param_6 = _957.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _967.xyz) * _967.w, (-dot(world_pos, _972.xyz)) * _972.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1002 = _921.xyz;\n        vec3 _1004 = _1002 - world_pos;\n        vec3 to_light = _1004;\n        float _1007 = length(_1004);\n        float reach = _1007;\n        bool front = true;\n        if (_941)\n        {\n            int param_8 = _913 + 7;\n            reach = max(_1007 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _913 + 4;\n            vec4 _1031 = fa_light_texel(param_9);\n            int param_10 = _913 + 5;\n            vec4 _1036 = fa_light_texel(param_10);\n            int param_11 = _913 + 6;\n            vec4 _1041 = fa_light_texel(param_11);\n            float _1042 = _1041.w;\n            int param_12 = _913 + 2;\n            vec3 _1049 = normalize(fa_light_texel(param_12).xyz);\n            bool _1051 = _1042 > 1.5;\n            bool _1059;\n            if (!_1051)\n            {\n                _1059 = dot(_1049, to_light) < 0.0;\n            }\n            else\n            {\n                _1059 = _1051;\n            }\n            front = _1059;\n            vec3 r = vec3(0.0);\n            vec3 _1068 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1072 = dot(n, n) > 0.5;\n            bool _1080;\n            if (_1072)\n            {\n                _1080 = dot(_1068, _1068) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1080 = _1072;\n            }\n            if (_1080)\n            {\n                r = reflect(-normalize(_1068), normalize(n));\n            }\n            vec3 param_13 = _1002;\n            vec3 param_14 = _1049;\n            vec3 param_15 = _1031.xyz;\n            vec3 param_16 = _1036.xyz;\n            float param_17 = _1031.w;\n            float param_18 = _1036.w;\n            float param_19 = _1042;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1116 = length(to_light);\n        dist = _1116;\n        l = to_light / vec3(max(_1116, 9.9999997473787516355514526367188e-05));\n        float _1130 = reach / max(_921.w, 0.001000000047497451305389404296875);\n        float _1136 = clamp(1.0 - (_1130 * _1130), 0.0, 1.0);\n        float _1138;\n        if (front)\n        {\n            _1138 = _1136 * _1136;\n        }\n        else\n        {\n            _1138 = 0.0;\n        }\n        atten = _1138;\n        bool _1149 = _929 < 2.5;\n        if ((_929 > 1.5) && _1149)\n        {\n            int param_22 = _913 + 2;\n            vec4 _1157 = fa_light_texel(param_22);\n            float _1167 = _1157.w;\n            int param_23 = _913 + 3;\n            vec4 _1172 = fa_light_texel(param_23);\n            float _1173 = _1172.x;\n            float cos_inner = _1173;\n            if (_1173 > 1.5)\n            {\n                cos_inner = mix(_1167, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1167, cos_inner, dot(-l, normalize(_1157.xyz)));\n        }\n        if (_917 && (_929 < 1.5))\n        {\n            int param_24 = _913 + 6;\n            vec4 _1197 = fa_light_texel(param_24);\n            if (_1197.z > 0.5)\n            {\n                vec3 _1205 = -to_light;\n                int param_25 = _913 + 4;\n                int param_26 = _913 + 5;\n                vec3 _1219 = fa_light_texel(param_25).xyz;\n                vec3 _1223 = fa_light_texel(param_26).xyz;\n                vec3 _1232 = vec3(dot(_1205, _1219), dot(_1205, _1223), dot(_1205, cross(_1219, _1223)));\n                vec3 param_27 = _1232;\n                int _1236 = fa_cube_face(param_27);\n                int param_28 = _1236;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1263 = vec2(dot(_1232, cross(param_29, param_30)), dot(_1232, param_30)) / vec2(max(dot(_1232, param_29), 9.9999997473787516355514526367188e-05));\n                int _1267 = _1236 / 3;\n                vec2 param_31 = _1197.xy + (vec2(float(_1236 - (_1267 * 3)), float(_1267)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1263.x), 0.5 - (0.5 * _1263.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _913 + 7;\n            vec4 _1297 = fa_light_texel(param_33);\n            if (_1297.z > 0.5)\n            {\n                int param_34 = _913 + 2;\n                int param_35 = _913 + 4;\n                int param_36 = _913 + 5;\n                vec2 param_37 = _1297.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_917 && _1149)\n            {\n                int param_42 = _913 + 6;\n                vec4 _1344 = fa_light_texel(param_42);\n                int param_43 = _913 + 7;\n                vec4 _1349 = fa_light_texel(param_43);\n                bool _1352 = _1344.z > 0.5;\n                bool _1359;\n                if (!_1352)\n                {\n                    _1359 = _1349.z > 0.5;\n                }\n                else\n                {\n                    _1359 = _1352;\n                }\n                if (_1359)\n                {\n                    int param_44 = _913 + 2;\n                    vec4 _1366 = fa_light_texel(param_44);\n                    vec3 _1370 = normalize(_1366.xyz);\n                    int param_45 = _913 + 4;\n                    vec4 _1375 = fa_light_texel(param_45);\n                    int param_46 = _913 + 5;\n                    vec4 _1380 = fa_light_texel(param_46);\n                    if (_1352)\n                    {\n                        vec3 _1388 = -to_light;\n                        float _1395 = _1366.w;\n                        float _1411 = 0.5 / max(dot(_1388, _1370) * (sqrt(max(1.0 - (_1395 * _1395), 0.0)) / max(_1395, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1344.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1388, _1375.xyz) * _1411), 0.5 - (dot(_1388, _1380.xyz) * _1411));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1349.z > 0.5)\n                    {\n                        vec2 param_49 = _1349.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1370;\n                        vec3 param_52 = _1375.xyz;\n                        vec3 param_53 = _1380.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _7134 = _926.xyz * atten;\n    if (_917)\n    {\n        _7134 *= fa_light_tint;\n    }\n    int _1480;\n    if (_943)\n    {\n        _1480 = 0;\n    }\n    else\n    {\n        _1480 = ((_929 > 1.5) && (_929 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _7134, atten, 1.0, dist, _1480);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2217;\n    if (i == 0)\n    {\n        _2217 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2233;\n        if (i == 1)\n        {\n            _2233 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2241;\n            if (i == 2)\n            {\n                _2241 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2241 = fa_shadows[24].w;\n            }\n            _2233 = _2241;\n        }\n        _2217 = _2233;\n    }\n    return _2217;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2274 = fa_shadow_depth(param, param_1);\n    float _2278;\n    if (conv.x < 0.5)\n    {\n        _2278 = _2274;\n    }\n    else\n    {\n        _2278 = (conv.y * conv.z) / (conv.z - (_2274 * (conv.z - conv.y)));\n    }\n    return _2278;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2205 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2205), sin(_2205)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2324 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2333;\n        if (k < 0.0)\n        {\n            _2333 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2333 = k;\n        }\n        float _2353 = clamp((_2333 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2324;\n            vec2 _2372 = fa_shadow_vogel(param_3, param_4, param_5) * _2353;\n            vec2 param_6 = uv + (_2372 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2384 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2384 < (zr - (length(_2372) * plane)))\n            {\n                sum += _2384;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2410 = sum / cnt;\n        float _2420;\n        if (k < 0.0)\n        {\n            _2420 = (-k) / max(_2410, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2420 = k;\n        }\n        radius = clamp(((max(zr - _2410, 0.0) * unit) * _2420) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2442 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2442; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2442;\n        float param_11 = _2324;\n        vec2 _2461 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2461 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2461) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2442);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2503 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2508 = clamp(dot(n, l), 0.0, 1.0);\n    float _2514 = sqrt(1.0 - (_2508 * _2508));\n    float _2521 = min(_2514 / max(_2508, 0.20000000298023223876953125), 4.0);\n    float _2526;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2526 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2526 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2551 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2526 * _2514)), 1.0);\n    float _2558 = _2551.x;\n    bool _2561 = _2558 < fa_shadows[ci * 1 + 16].x;\n    bool _2570;\n    if (!_2561)\n    {\n        _2570 = _2558 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2570 = _2561;\n    }\n    bool _2579;\n    if (!_2570)\n    {\n        _2579 = _2551.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2579 = _2570;\n    }\n    bool _2588;\n    if (!_2579)\n    {\n        _2588 = _2551.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2588 = _2579;\n    }\n    bool _2595;\n    if (!_2588)\n    {\n        _2595 = _2551.z > 1.0;\n    }\n    else\n    {\n        _2595 = _2588;\n    }\n    if (_2595)\n    {\n        return -1.0;\n    }\n    float _2603;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2603 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2603 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2551.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2551.z - ((_2603 * (1.0 + (0.5 * _2521))) / _2503);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2503;\n    float param_5 = _2503 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2521, 3.0)) * 0.5) / _2503;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2981 = int(fa_shadows[25].x + 0.5);\n    if (_2981 < 1)\n    {\n        return 1.0;\n    }\n    float _2996 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2981 - 1;\n    if (_2996 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3008 = _2981 > 1;\n    bool _3015;\n    if (_3008)\n    {\n        _3015 = _2996 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3015 = _3008;\n    }\n    if (_3015)\n    {\n        ci = 1;\n    }\n    bool _3019 = _2981 > 2;\n    bool _3026;\n    if (_3019)\n    {\n        _3026 = _2996 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3026 = _3019;\n    }\n    if (_3026)\n    {\n        ci = 2;\n    }\n    bool _3030 = _2981 > 3;\n    bool _3037;\n    if (_3030)\n    {\n        _3037 = _2996 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3037 = _3030;\n    }\n    if (_3037)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2981)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3063 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3063;\n        if (_3063 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3088;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3088 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3088 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3107 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3088, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3118 = clamp((_2996 - (fa_shadow_split_at(param_7) - _3107)) / _3107, 0.0, 1.0);\n        if (_3118 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2981)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3139 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3139;\n                if (_3139 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3118);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2661 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2668;\n    if (!_2661)\n    {\n        _2668 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2668 = _2661;\n    }\n    if (_2668)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2681 = fa_light_texel(param);\n    float _2682 = _2681.x;\n    if (_2682 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2691 = int(_2682 + 0.5);\n    int param_1 = _2691;\n    vec4 _2695 = fa_light_texel(param_1);\n    int param_2 = _2691 + 1;\n    vec4 _2700 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2703 = _2695.y;\n    if (_2703 > 0.0)\n    {\n        float _2720 = 1.0 - smoothstep(0.75 * _2703, _2703, length(world - fa_shadows[27].xyz));\n        fade = _2720;\n        if (_2720 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2695.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2744 = (_2691 + 2) + (face * 6);\n    int param_4 = _2744;\n    int param_5 = _2744 + 1;\n    int param_6 = _2744 + 3;\n    vec4 _2758 = fa_light_texel(param_6);\n    int param_7 = _2744 + 4;\n    vec4 _2763 = fa_light_texel(param_7);\n    int param_8 = _2744 + 5;\n    vec4 _2768 = fa_light_texel(param_8);\n    float _2780 = _2768.x * max(dot(_2758, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2785 = clamp(dot(n, l), 0.0, 1.0);\n    float _2808 = clamp(dot(n, _2758.xyz), -1.0, 1.0);\n    float _2827 = min(sqrt(1.0 - (_2808 * _2808)) / max(abs(dot(n, world - lpos)) / max(dot(_2758, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2830 = _2700.y;\n    float _2832;\n    if (_2830 > 0.0)\n    {\n        _2832 = _2830;\n    }\n    else\n    {\n        _2832 = 1.5 * _2780;\n    }\n    vec4 _2852 = vec4(world + (n * (_2832 * sqrt(1.0 - (_2785 * _2785)))), 1.0);\n    float _2856 = dot(_2758, _2852);\n    float _2859 = _2768.y;\n    if (_2856 < _2859)\n    {\n        return 1.0;\n    }\n    vec2 _2874 = vec2(dot(fa_light_texel(param_4), _2852), dot(fa_light_texel(param_5), _2852)) / vec2(_2856);\n    float _2876 = _2874.x;\n    bool _2879 = _2876 < _2763.x;\n    bool _2888;\n    if (!_2879)\n    {\n        _2888 = _2876 > _2763.z;\n    }\n    else\n    {\n        _2888 = _2879;\n    }\n    bool _2897;\n    if (!_2888)\n    {\n        _2897 = _2874.y < _2763.y;\n    }\n    else\n    {\n        _2897 = _2888;\n    }\n    bool _2906;\n    if (!_2897)\n    {\n        _2906 = _2874.y > _2763.w;\n    }\n    else\n    {\n        _2906 = _2897;\n    }\n    if (_2906)\n    {\n        return 1.0;\n    }\n    float _2912 = _2700.x;\n    float _2914;\n    if (_2912 > 0.0)\n    {\n        _2914 = _2912;\n    }\n    else\n    {\n        _2914 = 1.5 * _2780;\n    }\n    vec2 param_9 = _2874;\n    vec4 param_10 = _2763;\n    float param_11 = _2856 - (_2914 * (1.0 + (0.5 * _2827)));\n    float param_12 = _2780;\n    float param_13 = 1.0;\n    float param_14 = _2768.z * 0.25;\n    float param_15 = (_2780 * min(_2827, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2859, _2768.z);\n    int param_17 = int(_2695.z + 0.5);\n    float param_18 = _2695.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4469 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4476;\n    if (!_4469)\n    {\n        _4476 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4476 = _4469;\n    }\n    if (_4476)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4489 = fa_light_texel(param);\n    float _4490 = _4489.y;\n    float len = _4490;\n    if (_4490 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4502 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4512 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4502);\n    if (_4512 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4518 = len;\n    float _4521 = min(_4518, 0.89999997615814208984375 * dist);\n    len = _4521;\n    float _4526 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4502);\n    float _4531 = _4526 + (0.5 * _4521);\n    vec3 _4537 = world + (gn * _4526);\n    float _4539 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4603;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4554 = (float(k) + _4539) * 0.083333335816860198974609375;\n        vec3 _4562 = _4537 + (l * (_4554 * len));\n        vec4 _4568 = vec4(_4562, 1.0);\n        float _4574 = dot(fa_mesh_fs_params[28], _4568);\n        if (_4574 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4594 = vec2(dot(fa_mesh_fs_params[26], _4568), dot(fa_mesh_fs_params[27], _4568)) / vec2(_4574);\n        float _4598 = _4594.x * 0.5;\n        float _4599 = _4598 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4603 = (_4594.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4603 = 0.5 - (_4594.y * 0.5);\n        }\n        bool _4619 = _4599 < 0.0;\n        bool _4626;\n        if (!_4619)\n        {\n            _4626 = _4599 >= 1.0;\n        }\n        else\n        {\n            _4626 = _4619;\n        }\n        bool _4633;\n        if (!_4626)\n        {\n            _4633 = _4603 < 0.0;\n        }\n        else\n        {\n            _4633 = _4626;\n        }\n        bool _4640;\n        if (!_4633)\n        {\n            _4640 = _4603 >= 1.0;\n        }\n        else\n        {\n            _4640 = _4633;\n        }\n        if (_4640)\n        {\n            break;\n        }\n        vec4 _4659 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_4599, _4603) * fa_mesh_fs_params[24].zw), 0);\n        if (_4659.w < 0.5)\n        {\n            continue;\n        }\n        float _4678 = (dot(fa_mesh_fs_params[29].xyz, _4562) + fa_mesh_fs_params[29].w) - _4659.x;\n        if ((_4678 > _4526) && (_4678 < _4531))\n        {\n            occ = max(occ, (1.0 - (_4554 * _4554)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4599, 0.5 - _4598), min(_4603, 1.0 - _4603))));\n        }\n    }\n    return 1.0 - (occ * _4512);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4781 = fa_baked_keep(param);\n    if (_4781 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4807 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _7203 = _4807.color;\n    float _7204 = _4807.attenuation;\n    float _7205 = _4807.shadow;\n    bool _4810 = _4807.type == 0;\n    if (_4810 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4807.direction;\n        float _4821 = fa_shadow_factor(param_5, param_6);\n        _7205 = _4821;\n        _7203 *= _4821;\n    }\n    else\n    {\n        bool _4832 = _4807.type != 0;\n        bool _4838;\n        if (_4832)\n        {\n            _4838 = _7204 > 0.0;\n        }\n        else\n        {\n            _4838 = _4832;\n        }\n        if (_4838)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4807.direction;\n            float _4857 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7205 = _4857;\n            _7203 *= _4857;\n        }\n    }\n    bool _4867 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4873;\n    if (_4867)\n    {\n        _4873 = _7204 > 0.0;\n    }\n    else\n    {\n        _4873 = _4867;\n    }\n    if (_4873)\n    {\n        float _4880;\n        if (_4810)\n        {\n            _4880 = 1000000000.0;\n        }\n        else\n        {\n            _4880 = _4807._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4807.direction;\n        float param_18 = _4880;\n        float _4898 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7205 *= _4898;\n        _7203 *= _4898;\n    }\n    float _4911 = _7204;\n    float _4912 = _4911 * _4781;\n    _7204 = _4912;\n    return LightSample(_4807.direction, _7203, _4912, _7205, _4807._distance, _4807.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _4946 = v - (n * dot(v, n));\n    vec3 t = _4946;\n    float _4950 = dot(_4946, _4946);\n    float l2 = _4950;\n    if (_4950 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _4960;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _4960 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _4960 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _4960;\n        l2 = dot(_4960, _4960);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _4995 = dot(a, a);\n    float _4999 = dot(b, b);\n    if ((_4995 < 1.0000000195414813782625560981111e-24) || (_4999 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _5013 = a * inversesqrt(_4995);\n    vec3 _5018 = b * inversesqrt(_4999);\n    float _5022 = dot(_5013, _5018);\n    float _5025 = abs(_5022);\n    float g = (((((((((((0.0416471660137176513671875 * _5025) - 0.1924748718738555908203125) * _5025) + 0.4179156124591827392578125) * _5025) - 0.616057217121124267578125) * _5025) + 0.777722418308258056640625) * _5025) - 0.999542415142059326171875) * _5025) + 1.570791721343994140625;\n    if (_5022 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_5022 * _5022), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_5013, _5018) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _5082 = a.z > 0.0;\n    bool _5086 = b.z > 0.0;\n    if (_5082 && _5086)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5082 != _5086)\n        {\n            vec3 _5121 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5121.z = 0.0;\n            if (_5082)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _5121;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5121;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _5121;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5121;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _5170 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _5196 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _5222 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _5248 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _5170;\n    vec3 param_1 = _5196;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _5196;\n    vec3 param_7 = _5222;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _5222;\n    vec3 param_13 = _5248;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _5248;\n    vec3 param_19 = _5170;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _5398 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5422 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5438 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _5398;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _5422;\n    vec4 param_9 = m;\n    vec3 param_10 = _5398;\n    vec3 param_11 = _5422;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _5438;\n    vec4 param_14 = m;\n    vec3 param_15 = _5398;\n    vec3 param_16 = _5438;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5496 = fa_light_base(param);\n    int param_1 = _5496;\n    int param_2 = _5496 + 1;\n    int param_3 = _5496 + 2;\n    int param_4 = _5496 + 4;\n    vec4 _5518 = fa_light_texel(param_4);\n    int param_5 = _5496 + 5;\n    vec4 _5523 = fa_light_texel(param_5);\n    int param_6 = _5496 + 6;\n    vec4 _5528 = fa_light_texel(param_6);\n    float _5529 = _5528.w;\n    vec3 _5534 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5536 = _5529 < 1.5;\n    bool _5543;\n    if (_5536)\n    {\n        _5543 = dot(normalize(fa_light_texel(param_3).xyz), _5534) >= 0.0;\n    }\n    else\n    {\n        _5543 = _5536;\n    }\n    if (_5543)\n    {\n        return vec3(0.0);\n    }\n    bool _5552 = (_5529 > 0.5) && _5536;\n    float _5556 = _5552 ? 1.0539000034332275390625 : 1.0;\n    vec3 _5559 = _5518.xyz;\n    float _5561 = _5518.w;\n    vec3 _5567 = _5523.xyz;\n    float _5569 = _5523.w;\n    vec3 up = _5567 * (_5569 * _5556);\n    float _5575;\n    if (_5552)\n    {\n        _5575 = (3.1415927410125732421875 * _5561) * _5561;\n    }\n    else\n    {\n        _5575 = (4.0 * _5561) * _5569;\n    }\n    if (_5529 > 1.5)\n    {\n        vec3 _5601 = cross(_5559, -_5534);\n        vec3 perp = _5601;\n        float _5605 = dot(_5601, _5601);\n        vec3 _5608;\n        if (_5605 > 1.0000000133514319600180897396058e-10)\n        {\n            _5608 = perp * inversesqrt(_5605);\n        }\n        else\n        {\n            _5608 = _5567;\n        }\n        perp = _5608;\n        up = _5608 * _5569;\n    }\n    float _5629 = max(_5575, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _5639 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _5639;\n    vec3 param_10 = n;\n    vec3 param_11 = _5534;\n    vec3 _5647 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _5639;\n    vec3 param_13 = n;\n    vec3 param_14 = _5559 * (_5561 * _5556);\n    vec3 _5655 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _5639;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _5663 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _5529;\n    vec3 param_20 = _5647;\n    vec3 param_21 = _5655;\n    vec3 param_22 = _5663;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _5682 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _5682;\n    vec2 param_26 = _5682 + vec2(64.0, 0.0);\n    vec4 _5692 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5529;\n    vec3 param_29 = _5647;\n    vec3 param_30 = _5655;\n    vec3 param_31 = _5663;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5692.x) + ((vec3(f90) - f0) * _5692.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_5534, _5534)) + _5629) / _5629) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4206 = 1.0 / alpha;\n    return ((2.0 + _4206) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4206)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4241 = max(dot(L.nc, l), 0.0);\n    float _4247 = max(dot(L.nc, h), 0.0);\n    float _4256 = ((_4247 * _4247) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4256) * _4256)) * (0.5 / max(mix((2.0 * _4241) * L.coat_ndv, _4241 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4241)) * _4241;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5760;\n    if (L.sheen_on)\n    {\n        _5760 = L.sheen_scale;\n    }\n    else\n    {\n        _5760 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5760);\n    vec3 _5773 = normalize(l + v);\n    int param_10 = li;\n    vec3 _5784 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5793 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5773), 0.0);\n        float param_13 = _5793;\n        float param_14 = ndv;\n        result += ((L.sheen * _5784) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _5793)) * _5793) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _5773;\n        float param_18 = max(dot(v, _5773), 0.0);\n        result += (_5784 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4109 = tdh / at;\n    float _4113 = bdh / ab;\n    float _4125 = ((_4109 * _4109) + (_4113 * _4113)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4125) * _4125);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4305 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4384 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _4384) * _4384);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4305);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4305));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3515 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3518 = _3515.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3518 * _3518, exp2((-9.27999973297119140625) * ndv)) * _3518) + _3515.y)) + _3515.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3369 = rough * rough;\n    float _3399 = 0.60000002384185791015625 * _3369;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3369)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3399, 0.0500000007450580596923828125 + _3399, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3369 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3992;\n        if (L.aniso >= 0.0)\n        {\n            _3992 = L.b;\n        }\n        else\n        {\n            _3992 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3992, v), _3992), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4025 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4025.x) + (vec3(L.f90) * _4025.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4080 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4080.x) + _4080.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3557 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3557.x) + vec3(_3557.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3163 = int(fa_shadows[25].x + 0.5);\n    float _3173 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3178 = _3163 > 0;\n    bool _3187;\n    if (_3178)\n    {\n        int param = _3163 - 1;\n        _3187 = _3173 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3187 = _3178;\n    }\n    if (_3187)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3193 = _3163 > 1;\n        bool _3200;\n        if (_3193)\n        {\n            _3200 = _3173 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3200 = _3193;\n        }\n        if (_3200)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3206 = _3163 > 2;\n        bool _3213;\n        if (_3206)\n        {\n            _3213 = _3173 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3213 = _3206;\n        }\n        if (_3213)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3219 = _3163 > 3;\n        bool _3226;\n        if (_3219)\n        {\n            _3226 = _3173 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3226 = _3219;\n        }\n        if (_3226)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _6903 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6903 = -_6903;\n    }\n    vec3 _6266 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6903, fa_world_tangent, fa_uv, fa_vertex_color, _6266, gl_FrontFacing);\n    Surface _6274 = fa_standard_surface(param_1);\n    vec3 _6934 = _6274.albedo;\n    float _6935 = _6274.alpha;\n    vec3 _6936 = _6274.normal;\n    float _6937 = _6274.metallic;\n    float _6938 = _6274.roughness;\n    float _6939 = _6274.occlusion;\n    vec3 _6940 = _6274.emission;\n    float _6941 = _6274.clearcoat;\n    float _6942 = _6274.clearcoat_roughness;\n    vec3 _6943 = _6274.sheen_color;\n    float _6944 = _6274.sheen_roughness;\n    float _6945 = _6274.anisotropy;\n    float _6946 = _6274.anisotropy_rotation;\n    float _6947 = _6274.specular;\n    float _6948 = _6274.ior;\n    vec3 _6949 = _6274.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6903, fa_world_tangent, fa_uv, fa_vertex_color, _6266, gl_FrontFacing);\n    Surface param_3 = _6274;\n    surface(param_2, param_3);\n    _6934 = param_3.albedo;\n    _6935 = param_3.alpha;\n    _6936 = param_3.normal;\n    _6937 = param_3.metallic;\n    _6938 = param_3.roughness;\n    _6939 = param_3.occlusion;\n    _6940 = param_3.emission;\n    _6941 = param_3.clearcoat;\n    _6942 = param_3.clearcoat_roughness;\n    _6943 = param_3.sheen_color;\n    _6944 = param_3.sheen_roughness;\n    _6945 = param_3.anisotropy;\n    _6946 = param_3.anisotropy_rotation;\n    _6947 = param_3.specular;\n    _6948 = param_3.ior;\n    _6949 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6903;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6934 = param_6;\n    _6936 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6934;\n    }\n    else\n    {\n        vec3 _6313 = normalize(_6936);\n        float _6320 = clamp(_6937, 0.0, 1.0);\n        float _6324 = clamp(_6938, 0.0500000007450580596923828125, 1.0);\n        float _6328 = _6324 * _6324;\n        float _6332 = _6328 * _6328;\n        float _6337 = max(dot(_6313, _6266), 9.9999997473787516355514526367188e-05);\n        vec3 _6343 = _6934 * (1.0 - _6320);\n        vec3 _6350 = mix(vec3(0.039999999105930328369140625), _6934, vec3(_6320));\n        vec3 f0 = _6350;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _6903, fa_world_tangent, fa_uv, fa_vertex_color, _6266, gl_FrontFacing);\n        Surface param_9 = Surface(_6934, _6935, _6936, _6937, _6938, _6939, _6940, _6941, _6942, _6943, _6944, _6945, _6946, _6947, _6948, _6949);\n        vec3 param_10 = _6313;\n        vec3 param_11 = _6266;\n        float param_12 = _6320;\n        float param_13 = _6324;\n        vec3 param_14 = _6350;\n        FaLayers _6366 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _6313;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _6343) * _6939;\n        if (_6366.on)\n        {\n            lit *= _6366.base_scale;\n        }\n        int _6388 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6388; ln++)\n        {\n            int param_16 = ln;\n            int _6401 = fa_cl_light(param_16);\n            int param_17 = _6401;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _6401;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _6903;\n            LightSample _6417 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6425 = max(dot(_6313, _6417.direction), 0.0);\n            float _6431 = _6417.attenuation * _6417.shadow;\n            vec3 _6436 = normalize(_6417.direction + _6266);\n            float _6441 = max(dot(_6313, _6436), 0.0);\n            float _6446 = max(dot(_6266, _6436), 0.0);\n            bool _6453;\n            if (fa_light_is_area)\n            {\n                _6453 = !_6366.on;\n            }\n            else\n            {\n                _6453 = fa_light_is_area;\n            }\n            if (_6453)\n            {\n                int param_21 = _6401;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _6313;\n                vec3 param_24 = _6266;\n                vec3 param_25 = _6343;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _6324;\n                float param_29 = _6337;\n                float param_30 = _6431;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6366;\n                    int param_32 = _6401;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _6313;\n                    vec3 param_35 = _6266;\n                    vec3 param_36 = _6417.direction;\n                    vec3 param_37 = _6343;\n                    vec3 param_38 = f0;\n                    float param_39 = _6324;\n                    float param_40 = _6337;\n                    float param_41 = _6431;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6366.on)\n                    {\n                        FaLayers param_42 = _6366;\n                        vec3 param_43 = _6343;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _6313;\n                        vec3 param_46 = _6266;\n                        vec3 param_47 = _6417.direction;\n                        vec3 param_48 = _6436;\n                        float param_49 = _6425;\n                        float param_50 = _6337;\n                        float param_51 = _6441;\n                        float param_52 = _6446;\n                        float param_53 = _6328;\n                        float param_54 = _6332;\n                        int param_55 = _6401;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6431));\n                    }\n                    else\n                    {\n                        float _6559 = ((_6441 * _6441) * (_6332 - 1.0)) + 1.0;\n                        int param_56 = _6401;\n                        lit += (((_6343 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _6446, 5.0))) * (((_6332 / ((3.1415927410125732421875 * _6559) * _6559)) * (0.5 / max(mix((2.0 * _6425) * _6337, _6425 + _6337, _6328), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _6425))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6425 * _6431));\n                    }\n                }\n            }\n        }\n        if (_6366.on)\n        {\n            FaLayers param_57 = _6366;\n            vec3 param_58 = _6313;\n            vec3 param_59 = _6266;\n            vec3 param_60 = f0;\n            float param_61 = _6324;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6939);\n        }\n        else\n        {\n            vec3 param_62 = _6313;\n            vec3 param_63 = _6266;\n            vec3 param_64 = f0;\n            float param_65 = _6324;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6939);\n        }\n        result = lit;\n    }\n    vec3 _6654 = result;\n    vec3 _6655 = _6654 + _6940;\n    result = _6655;\n    vec3 param_66 = _6655;\n    vec3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6664 = fa_mesh_fs_params[7].w > 0.0;\n    bool _6671;\n    if (!_6664)\n    {\n        _6671 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _6671 = _6664;\n    }\n    if (_6671)\n    {\n        vec3 _6680 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6686 = dot(_6680, fa_mesh_fs_params[9].xyz);\n        bool _6690 = fa_mesh_fs_params[9].w > 0.5;\n        float _6691;\n        if (_6690)\n        {\n            _6691 = _6686;\n        }\n        else\n        {\n            _6691 = length(_6680);\n        }\n        float _6703 = _6691 - fa_mesh_fs_params[8].x;\n        if (_6703 > 0.0)\n        {\n            float _6712 = fa_mesh_fs_params[7].w * _6703;\n            float tau = _6712 * _6712;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6728;\n                if (_6690)\n                {\n                    _6728 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6686);\n                }\n                else\n                {\n                    _6728 = fa_mesh_fs_params[0].y;\n                }\n                float _6749 = mix(_6728, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6691, 0.0, 1.0));\n                float _6753 = fa_world_pos.y - _6749;\n                float _6758 = _6749 - fa_mesh_fs_params[8].z;\n                float _6763 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6766 = _6758 <= 0.0;\n                bool _6767 = !_6766;\n                bool _6773;\n                if (_6767)\n                {\n                    _6773 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6773 = _6766;\n                }\n                float _6774;\n                if (_6773)\n                {\n                    _6774 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6774 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6758, 80.0));\n                }\n                bool _6801;\n                if (_6767)\n                {\n                    _6801 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6801 = _6766;\n                }\n                float _6802;\n                if (_6801)\n                {\n                    _6802 = fa_mesh_fs_params[8].y * _6758;\n                }\n                else\n                {\n                    _6802 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6758, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6827 = _6763 <= 0.0;\n                bool _6834;\n                if (!_6827)\n                {\n                    _6834 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6834 = _6827;\n                }\n                float _6835;\n                if (_6834)\n                {\n                    _6835 = fa_mesh_fs_params[8].y * _6763;\n                }\n                else\n                {\n                    _6835 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6763, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _6862;\n                if (abs(_6753) < 0.001000000047497451305389404296875)\n                {\n                    _6862 = _6774;\n                }\n                else\n                {\n                    _6862 = (_6835 - _6802) / _6753;\n                }\n                tau += (_6703 * max(_6862, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6935);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_560",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 39,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2227",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
                "offset": 0,
                "glsl_name": "fa_shadows"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering"
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1,
            "glsl_name": "fa_light_tex_fa_shadow_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10,
            "glsl_name": "fa_decal_tex_fa_env_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10,
            "glsl_name": "fa_lightmap_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_388, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3657[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[39];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1498 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1505;\n    if (!_1498)\n    {\n        _1505 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1505 = _1498;\n    }\n    bool _1513;\n    if (!_1505)\n    {\n        _1513 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1513 = _1505;\n    }\n    bool _1520;\n    if (!_1513)\n    {\n        _1520 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1520 = _1513;\n    }\n    bool _1527;\n    if (!_1520)\n    {\n        _1527 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1527 = _1520;\n    }\n    if (_1527)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1537 = vec4(world_pos, 1.0);\n    float _1543 = dot(fa_mesh_fs_params[16], _1537);\n    if (!(_1543 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1565 = vec2(dot(fa_mesh_fs_params[14], _1537), dot(fa_mesh_fs_params[15], _1537)) / vec2(_1543);\n    int _1569 = int(fa_mesh_fs_params[18].x);\n    int _1573 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1573) + clamp(int(floor(((_1565.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1573 - 1)) * _1569)) + clamp(int(floor(((_1565.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1569 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1649 = fa_cluster_texel(param);\n    return ivec2(int(_1649.x), int(_1649.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4755 = fa_cluster_lookup(param);\n    fa_cl_slot = _4755.x;\n    fa_cl_local = _4755.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5899 = fa_linear_to_srgb(param);\n        c = _5899;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5907 = fa_srgb_to_linear(param_1);\n            c = _5907;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _442;\n    if (i.front_facing)\n    {\n        _442 = i.world_normal;\n    }\n    else\n    {\n        _442 = -i.world_normal;\n    }\n    vec3 _466 = normalize(i.world_tangent.xyz - (_442 * dot(_442, i.world_tangent.xyz)));\n    vec3 _493 = normalize(((_466 * m.x) + ((cross(_442, _466) * i.world_tangent.w) * m.y)) + (_442 * m.z));\n    vec3 _496;\n    if (i.front_facing)\n    {\n        _496 = _493;\n    }\n    else\n    {\n        _496 = -_493;\n    }\n    return _496;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5938 = fa_tex_fix(param_2, param_3);\n    vec4 _7398 = base_t;\n    _7398.x = _5938.x;\n    _7398.y = _5938.y;\n    _7398.z = _5938.z;\n    base_t = _7398;\n    vec4 _5952 = (_7398 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _7223 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5984 = fa_tex_fix(param_6, param_7);\n        vec3 _5987 = (_5984 * 2.0) - vec3(1.0);\n        vec2 _5992 = _5987.xy * fa_mesh_fs_params[6].x;\n        vec3 _7406 = _5987;\n        _7406.x = _5992.x;\n        _7406.y = _5992.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7406;\n        _7223 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _6020 = fa_tex_fix(param_12, param_13);\n    vec4 _7409 = mrt;\n    _7409.x = _6020.x;\n    _7409.y = _6020.y;\n    _7409.z = _6020.z;\n    mrt = _7409;\n    vec4 _6048 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _6048.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _6059 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _6089 = fa_tex_fix(param_20, param_21);\n    float _7228 = fa_mesh_fs_params[20].x;\n    float _7229 = fa_mesh_fs_params[20].y;\n    float _7232 = fa_mesh_fs_params[20].z;\n    float _7231 = fa_mesh_fs_params[21].w;\n    float _7234 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _7228 *= _6059.y;\n            _7229 *= _6059.z;\n            _7231 *= _6048.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _7232 *= mrt.x;\n            _7234 *= mrt.w;\n        }\n    }\n    return Surface(_5952.xyz, _5952.w, _7223, clamp(fa_mesh_fs_params[5].x * _6020.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _6020.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_6059.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _6089), _7228, _7229, fa_mesh_fs_params[21].xyz, _7231, _7232, fa_mesh_fs_params[20].w, _7234, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += vec3(0.5 + (0.5 * sin(fa_mesh_fs_params[13].x * 3.0)), 0.25 * fract(fa_mesh_fs_params[13].x), 0.0);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1729 = rect.zw - rect.xy;\n    vec2 _1733 = _1729 * atlas;\n    vec2 _1737 = ddx * _1733;\n    vec2 _1741 = ddy * _1733;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1729), clamp(0.5 * log2(max(max(dot(_1737, _1737), dot(_1741, _1741)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1774 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1781;\n    if (!_1774)\n    {\n        _1781 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1781 = _1774;\n    }\n    if (_1781)\n    {\n        return;\n    }\n    vec3 _1787 = dFdx(world_pos);\n    vec3 _1790 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1794 = fa_cluster_texel(param);\n    int _1798 = int(_1794.w);\n    if (_1798 < 1)\n    {\n        return;\n    }\n    int _1808 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1808;\n    vec4 _1812 = fa_light_texel(param_1);\n    vec2 _1815 = _1812.yz;\n    int _1819 = int(_1812.w);\n    int param_2 = _1808 + 1;\n    vec4 _1824 = fa_light_texel(param_2);\n    float _1825 = _1824.x;\n    int _1831 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1835 = int(_1794.z);\n    vec3 _2100;\n    for (int k = 0; k < _1798; k++)\n    {\n        int _1848 = _1835 + k;\n        int param_3 = _1819 + (_1848 >> 2);\n        int _1865 = (_1808 + 2) + (int(fa_light_texel(param_3)[_1848 & 3]) * 7);\n        int param_4 = _1865 + 6;\n        vec4 _1870 = fa_light_texel(param_4);\n        if (((int(_1870.w + 0.5) >> _1831) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1865;\n        vec4 _1885 = fa_light_texel(param_5);\n        int param_6 = _1865 + 1;\n        vec4 _1890 = fa_light_texel(param_6);\n        int param_7 = _1865 + 2;\n        vec4 _1895 = fa_light_texel(param_7);\n        vec3 _1898 = _1885.xyz;\n        float _1903 = dot(_1898, world_pos) + _1885.w;\n        vec3 _1905 = _1890.xyz;\n        float _1910 = dot(_1905, world_pos) + _1890.w;\n        vec3 _1912 = _1895.xyz;\n        float _1917 = dot(_1912, world_pos) + _1895.w;\n        bool _1922 = abs(_1903) > 0.5;\n        bool _1930;\n        if (!_1922)\n        {\n            _1930 = abs(_1910) > 0.5;\n        }\n        else\n        {\n            _1930 = _1922;\n        }\n        bool _1938;\n        if (!_1930)\n        {\n            _1938 = abs(_1917) > 0.5;\n        }\n        else\n        {\n            _1938 = _1930;\n        }\n        if (_1938)\n        {\n            continue;\n        }\n        float _1953 = clamp(dot(geo_normal, normalize(_1912)) * _1870.z, 0.0, 1.0);\n        if (_1953 <= 0.0)\n        {\n            continue;\n        }\n        float _1973 = (clamp((0.5 - abs(_1917)) * 10.0, 0.0, 1.0) * _1953) * _1870.x;\n        vec2 _1981 = vec2(_1903 + 0.5, 0.5 - _1910);\n        vec2 _1991 = vec2(dot(_1898, _1787), dot(_1905, _1787));\n        vec2 _2001 = vec2(dot(_1898, _1790), dot(_1905, _1790));\n        int param_8 = _1865 + 5;\n        vec4 _2006 = fa_light_texel(param_8);\n        int param_9 = _1865 + 3;\n        vec4 _2011 = fa_light_texel(param_9);\n        int param_10 = _1865 + 4;\n        vec4 _2016 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2006.xyz;\n        bool _2026 = _2011.z > _2011.x;\n        if (_2026)\n        {\n            vec4 param_11 = _2011;\n            vec2 param_12 = _1981;\n            vec2 param_13 = _1815;\n            vec2 param_14 = _1991;\n            vec2 param_15 = _2001;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1825 > 0.5) && (_1825 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2052 = fa_dc_to_linear(param_16);\n                vec4 _7303 = tx;\n                _7303.x = _2052.x;\n                _7303.y = _2052.y;\n                _7303.z = _2052.z;\n                tx = _7303;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1973 * tex_a) * _2006.w, 0.0, 1.0)));\n        if (_2016.z > _2016.x)\n        {\n            vec4 param_17 = _2016;\n            vec2 param_18 = _1981;\n            vec2 param_19 = _1815;\n            vec2 param_20 = _1991;\n            vec2 param_21 = _2001;\n            vec4 _2096 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1825 > 1.5)\n            {\n                vec3 param_22 = _2096.xyz;\n                vec3 _2106 = fa_dc_to_srgb(param_22);\n                _2100 = _2106;\n            }\n            else\n            {\n                _2100 = _2096.xyz;\n            }\n            vec3 _2115 = (_2100 * 2.0) - vec3(1.0);\n            vec2 _2120 = _2115.xy * _1870.y;\n            vec3 _2142 = (normalize(_1898) * _2120.x) + (normalize(_1905) * _2120.y);\n            vec3 _2145 = normalize(normal);\n            normal = normalize(mix(_2145, normalize((_2145 * max(_2115.z, 0.0500000007450580596923828125)) + (_2142 - (_2145 * dot(_2145, _2142)))), vec3(clamp(_1973 * (_2026 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3583 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3590 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3593 = int(_3583);\n    int _3596 = int(_3590);\n    float _3606 = _3590 - float(_3596);\n    int _3661 = (_3593 * 9) + _3596;\n    int _3681 = ((_3593 + 1) * 9) + _3596;\n    return mix(mix(_3657[_3661], _3657[_3661 + 1], _3606), mix(_3657[_3681], _3657[_3681 + 1], _3606), _3583 - float(_3593));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _7146 = false;\n    float _7147 = 1.0;\n    float _7148 = 1.0;\n    float _7149 = 1.0;\n    float _7150 = 0.0;\n    float _7151 = 0.0;\n    float _7152 = 0.0;\n    float _7153 = 0.0;\n    float _7155 = 1.0;\n    bool _7156 = false;\n    vec3 _7157 = vec3(0.0);\n    float _7158 = 1.0;\n    float _7159 = 1.0;\n    float _7160 = 1.0;\n    float _7161 = 0.0;\n    float _7162 = 0.0;\n    vec3 _7163 = vec3(1.0, 0.0, 0.0);\n    vec3 _7164 = vec3(0.0, 0.0, 1.0);\n    float _7165 = 1.0;\n    float _7166 = 1.0;\n    float _3732 = clamp(s.specular, 0.0, 1.0);\n    float _3736 = clamp(s.ior, 1.0, 3.0);\n    bool _3741 = (_3732 != 1.0) || (_3736 != 1.5);\n    bool _3750;\n    if (!_3741)\n    {\n        _3750 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3750 = _3741;\n    }\n    if (_3750)\n    {\n        float _3758 = (_3736 - 1.0) / (_3736 + 1.0);\n        f0 = mix(min(vec3(_3758 * _3758) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3732, s.albedo, vec3(metallic));\n        _7147 = mix(_3732, 1.0, metallic);\n        _7146 = true;\n    }\n    float _3785 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3785 > 0.0)\n    {\n        float _3793 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _7150 = _3785;\n        _7151 = _3793;\n        float _3800 = _3793 * _3793;\n        _7152 = _3800;\n        _7153 = _3800 * _3800;\n        float _3812 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _7155 = _3812;\n        _7148 = 1.0 - (_3785 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3812, 0.0, 1.0), 5.0))));\n        _7146 = true;\n    }\n    vec3 _3831 = max(s.sheen_color, vec3(0.0));\n    float _3840 = max(_3831.x, max(_3831.y, _3831.z));\n    if (_3840 > 0.0)\n    {\n        float _3848 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _7156 = true;\n        _7157 = _3831;\n        _7158 = _3848;\n        _7159 = _3848 * _3848;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3848;\n        float _3865 = fa_sheen_albedo(param, param_1);\n        _7161 = _3865;\n        _7160 = 1.0 - min(_3840 * _3865, 1.0);\n        _7146 = true;\n    }\n    _7149 = _7148 * _7160;\n    float _3884 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3884 != 0.0)\n    {\n        vec3 _3899 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3899;\n        if (dot(_3899, _3899) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3911 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3911.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3911.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3911.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3915 = t;\n        vec3 _3916 = normalize(_3915);\n        t = _3916;\n        vec3 _3941 = normalize((_3916 * cos(s.anisotropy_rotation)) + ((cross(n, _3916) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _7163 = _3941;\n        _7164 = cross(n, _3941);\n        float _3951 = roughness * roughness;\n        float _3957 = mix(_3951, 1.0, _3884 * _3884);\n        bool _3959 = _3884 > 0.0;\n        _7165 = _3959 ? _3957 : _3951;\n        _7166 = _3959 ? _3951 : _3957;\n        _7162 = _3884;\n        _7146 = true;\n    }\n    return FaLayers(_7146, _7147, _7148, _7149, _7150, _7151, _7152, _7153, i.world_normal, _7155, _7156, _7157, _7158, _7159, _7160, _7161, _7162, _7163, _7164, _7165, _7166);\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3340 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3340;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[30].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 30].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[30].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4725;\n    if (fa_lm.z > 0.5)\n    {\n        _4725 = 0.0;\n    }\n    else\n    {\n        _4725 = 1.0 - clamp(fa_mesh_fs_params[30].w, 0.0, 1.0);\n    }\n    bool _4736 = _4725 < 1.0;\n    bool _4742;\n    if (_4736)\n    {\n        int param = li;\n        _4742 = fa_light_baked(param);\n    }\n    else\n    {\n        _4742 = _4736;\n    }\n    return _4742 ? _4725 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _747 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _760 = (c - (ru * hx)) - p;\n        vec3 _766 = ru * (2.0 * hx);\n        float _772 = max(dot(_766, _766), 9.9999999392252902907785028219223e-09);\n        float _776 = dot(_760, _766);\n        float t = clamp((-_776) / _772, 0.0, 1.0);\n        if (_747)\n        {\n            float _791 = dot(r, _766);\n            float _797 = _772 - (_791 * _791);\n            if (abs(_797) > (9.9999997473787516355514526367188e-06 * _772))\n            {\n                t = clamp(((dot(r, _760) * _791) - _776) / _797, 0.0, 1.0);\n            }\n        }\n        return (p + _760) + (_766 * t);\n    }\n    vec3 q = p;\n    float _829 = dot(r, axis);\n    bool _837;\n    if (_747)\n    {\n        _837 = abs(_829) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _837 = _747;\n    }\n    if (_837)\n    {\n        float _847 = dot(c - p, axis) / _829;\n        if (_847 > 0.0)\n        {\n            q = p + (r * _847);\n        }\n    }\n    vec3 _860 = q - c;\n    vec2 xy = vec2(dot(_860, ru), dot(_860, uu));\n    if (shape > 0.5)\n    {\n        float _875 = length(xy);\n        if (_875 > hx)\n        {\n            xy *= (hx / _875);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _508 = abs(d);\n    float _510 = _508.x;\n    float _512 = _508.y;\n    bool _513 = _510 >= _512;\n    bool _521;\n    if (_513)\n    {\n        _521 = _510 >= _508.z;\n    }\n    else\n    {\n        _521 = _513;\n    }\n    int _522;\n    if (_521)\n    {\n        _522 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _537;\n        if (_512 >= _508.z)\n        {\n            _537 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _537 = (d.z > 0.0) ? 4 : 5;\n        }\n        _522 = _537;\n    }\n    return _522;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _667 = dot(d, right);\n    float _671 = dot(d, up);\n    float _682;\n    if (((_667 * _667) + (_671 * _671)) > 1.0000000133514319600180897396058e-10)\n    {\n        _682 = atan(_671, _667) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _682 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_682 - floor(_682)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _913 = fa_light_base(param);\n    bool _917 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _913;\n    vec4 _921 = fa_light_texel(param_1);\n    int param_2 = _913 + 1;\n    vec4 _926 = fa_light_texel(param_2);\n    float _929 = _926.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _941 = _917 && (_929 > 2.5);\n    fa_light_is_area = _941;\n    bool _943 = _929 < 0.5;\n    vec3 l;\n    if (_943)\n    {\n        l = normalize(_921.xyz);\n        if (_917)\n        {\n            int param_3 = _913 + 6;\n            vec4 _957 = fa_light_texel(param_3);\n            if (_957.z > 0.5)\n            {\n                int param_4 = _913 + 4;\n                vec4 _967 = fa_light_texel(param_4);\n                int param_5 = _913 + 5;\n                vec4 _972 = fa_light_texel(param_5);\n                vec2 param_6 = _957.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _967.xyz) * _967.w, (-dot(world_pos, _972.xyz)) * _972.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1002 = _921.xyz;\n        vec3 _1004 = _1002 - world_pos;\n        vec3 to_light = _1004;\n        float _1007 = length(_1004);\n        float reach = _1007;\n        bool front = true;\n        if (_941)\n        {\n            int param_8 = _913 + 7;\n            reach = max(_1007 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _913 + 4;\n            vec4 _1031 = fa_light_texel(param_9);\n            int param_10 = _913 + 5;\n            vec4 _1036 = fa_light_texel(param_10);\n            int param_11 = _913 + 6;\n            vec4 _1041 = fa_light_texel(param_11);\n            float _1042 = _1041.w;\n            int param_12 = _913 + 2;\n            vec3 _1049 = normalize(fa_light_texel(param_12).xyz);\n            bool _1051 = _1042 > 1.5;\n            bool _1059;\n            if (!_1051)\n            {\n                _1059 = dot(_1049, to_light) < 0.0;\n            }\n            else\n            {\n                _1059 = _1051;\n            }\n            front = _1059;\n            vec3 r = vec3(0.0);\n            vec3 _1068 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1072 = dot(n, n) > 0.5;\n            bool _1080;\n            if (_1072)\n            {\n                _1080 = dot(_1068, _1068) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1080 = _1072;\n            }\n            if (_1080)\n            {\n                r = reflect(-normalize(_1068), normalize(n));\n            }\n            vec3 param_13 = _1002;\n            vec3 param_14 = _1049;\n            vec3 param_15 = _1031.xyz;\n            vec3 param_16 = _1036.xyz;\n            float param_17 = _1031.w;\n            float param_18 = _1036.w;\n            float param_19 = _1042;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1116 = length(to_light);\n        dist = _1116;\n        l = to_light / vec3(max(_1116, 9.9999997473787516355514526367188e-05));\n        float _1130 = reach / max(_921.w, 0.001000000047497451305389404296875);\n        float _1136 = clamp(1.0 - (_1130 * _1130), 0.0, 1.0);\n        float _1138;\n        if (front)\n        {\n            _1138 = _1136 * _1136;\n        }\n        else\n        {\n            _1138 = 0.0;\n        }\n        atten = _1138;\n        bool _1149 = _929 < 2.5;\n        if ((_929 > 1.5) && _1149)\n        {\n            int param_22 = _913 + 2;\n            vec4 _1157 = fa_light_texel(param_22);\n            float _1167 = _1157.w;\n            int param_23 = _913 + 3;\n            vec4 _1172 = fa_light_texel(param_23);\n            float _1173 = _1172.x;\n            float cos_inner = _1173;\n            if (_1173 > 1.5)\n            {\n                cos_inner = mix(_1167, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1167, cos_inner, dot(-l, normalize(_1157.xyz)));\n        }\n        if (_917 && (_929 < 1.5))\n        {\n            int param_24 = _913 + 6;\n            vec4 _1197 = fa_light_texel(param_24);\n            if (_1197.z > 0.5)\n            {\n                vec3 _1205 = -to_light;\n                int param_25 = _913 + 4;\n                int param_26 = _913 + 5;\n                vec3 _1219 = fa_light_texel(param_25).xyz;\n                vec3 _1223 = fa_light_texel(param_26).xyz;\n                vec3 _1232 = vec3(dot(_1205, _1219), dot(_1205, _1223), dot(_1205, cross(_1219, _1223)));\n                vec3 param_27 = _1232;\n                int _1236 = fa_cube_face(param_27);\n                int param_28 = _1236;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1263 = vec2(dot(_1232, cross(param_29, param_30)), dot(_1232, param_30)) / vec2(max(dot(_1232, param_29), 9.9999997473787516355514526367188e-05));\n                int _1267 = _1236 / 3;\n                vec2 param_31 = _1197.xy + (vec2(float(_1236 - (_1267 * 3)), float(_1267)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1263.x), 0.5 - (0.5 * _1263.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _913 + 7;\n            vec4 _1297 = fa_light_texel(param_33);\n            if (_1297.z > 0.5)\n            {\n                int param_34 = _913 + 2;\n                int param_35 = _913 + 4;\n                int param_36 = _913 + 5;\n                vec2 param_37 = _1297.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_917 && _1149)\n            {\n                int param_42 = _913 + 6;\n                vec4 _1344 = fa_light_texel(param_42);\n                int param_43 = _913 + 7;\n                vec4 _1349 = fa_light_texel(param_43);\n                bool _1352 = _1344.z > 0.5;\n                bool _1359;\n                if (!_1352)\n                {\n                    _1359 = _1349.z > 0.5;\n                }\n                else\n                {\n                    _1359 = _1352;\n                }\n                if (_1359)\n                {\n                    int param_44 = _913 + 2;\n                    vec4 _1366 = fa_light_texel(param_44);\n                    vec3 _1370 = normalize(_1366.xyz);\n                    int param_45 = _913 + 4;\n                    vec4 _1375 = fa_light_texel(param_45);\n                    int param_46 = _913 + 5;\n                    vec4 _1380 = fa_light_texel(param_46);\n                    if (_1352)\n                    {\n                        vec3 _1388 = -to_light;\n                        float _1395 = _1366.w;\n                        float _1411 = 0.5 / max(dot(_1388, _1370) * (sqrt(max(1.0 - (_1395 * _1395), 0.0)) / max(_1395, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1344.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1388, _1375.xyz) * _1411), 0.5 - (dot(_1388, _1380.xyz) * _1411));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1349.z > 0.5)\n                    {\n                        vec2 param_49 = _1349.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1370;\n                        vec3 param_52 = _1375.xyz;\n                        vec3 param_53 = _1380.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _7134 = _926.xyz * atten;\n    if (_917)\n    {\n        _7134 *= fa_light_tint;\n    }\n    int _1480;\n    if (_943)\n    {\n        _1480 = 0;\n    }\n    else\n    {\n        _1480 = ((_929 > 1.5) && (_929 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _7134, atten, 1.0, dist, _1480);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2217;\n    if (i == 0)\n    {\n        _2217 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2233;\n        if (i == 1)\n        {\n            _2233 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2241;\n            if (i == 2)\n            {\n                _2241 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2241 = fa_shadows[24].w;\n            }\n            _2233 = _2241;\n        }\n        _2217 = _2233;\n    }\n    return _2217;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2274 = fa_shadow_depth(param, param_1);\n    float _2278;\n    if (conv.x < 0.5)\n    {\n        _2278 = _2274;\n    }\n    else\n    {\n        _2278 = (conv.y * conv.z) / (conv.z - (_2274 * (conv.z - conv.y)));\n    }\n    return _2278;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2205 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2205), sin(_2205)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2324 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2333;\n        if (k < 0.0)\n        {\n            _2333 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2333 = k;\n        }\n        float _2353 = clamp((_2333 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2324;\n            vec2 _2372 = fa_shadow_vogel(param_3, param_4, param_5) * _2353;\n            vec2 param_6 = uv + (_2372 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2384 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2384 < (zr - (length(_2372) * plane)))\n            {\n                sum += _2384;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2410 = sum / cnt;\n        float _2420;\n        if (k < 0.0)\n        {\n            _2420 = (-k) / max(_2410, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2420 = k;\n        }\n        radius = clamp(((max(zr - _2410, 0.0) * unit) * _2420) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2442 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2442; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2442;\n        float param_11 = _2324;\n        vec2 _2461 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2461 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2461) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2442);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2503 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2508 = clamp(dot(n, l), 0.0, 1.0);\n    float _2514 = sqrt(1.0 - (_2508 * _2508));\n    float _2521 = min(_2514 / max(_2508, 0.20000000298023223876953125), 4.0);\n    float _2526;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2526 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2526 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2551 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2526 * _2514)), 1.0);\n    float _2558 = _2551.x;\n    bool _2561 = _2558 < fa_shadows[ci * 1 + 16].x;\n    bool _2570;\n    if (!_2561)\n    {\n        _2570 = _2558 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2570 = _2561;\n    }\n    bool _2579;\n    if (!_2570)\n    {\n        _2579 = _2551.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2579 = _2570;\n    }\n    bool _2588;\n    if (!_2579)\n    {\n        _2588 = _2551.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2588 = _2579;\n    }\n    bool _2595;\n    if (!_2588)\n    {\n        _2595 = _2551.z > 1.0;\n    }\n    else\n    {\n        _2595 = _2588;\n    }\n    if (_2595)\n    {\n        return -1.0;\n    }\n    float _2603;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2603 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2603 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2551.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2551.z - ((_2603 * (1.0 + (0.5 * _2521))) / _2503);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2503;\n    float param_5 = _2503 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2521, 3.0)) * 0.5) / _2503;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2981 = int(fa_shadows[25].x + 0.5);\n    if (_2981 < 1)\n    {\n        return 1.0;\n    }\n    float _2996 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2981 - 1;\n    if (_2996 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3008 = _2981 > 1;\n    bool _3015;\n    if (_3008)\n    {\n        _3015 = _2996 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3015 = _3008;\n    }\n    if (_3015)\n    {\n        ci = 1;\n    }\n    bool _3019 = _2981 > 2;\n    bool _3026;\n    if (_3019)\n    {\n        _3026 = _2996 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3026 = _3019;\n    }\n    if (_3026)\n    {\n        ci = 2;\n    }\n    bool _3030 = _2981 > 3;\n    bool _3037;\n    if (_3030)\n    {\n        _3037 = _2996 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3037 = _3030;\n    }\n    if (_3037)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2981)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3063 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3063;\n        if (_3063 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3088;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3088 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3088 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3107 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3088, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3118 = clamp((_2996 - (fa_shadow_split_at(param_7) - _3107)) / _3107, 0.0, 1.0);\n        if (_3118 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2981)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3139 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3139;\n                if (_3139 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3118);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2661 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2668;\n    if (!_2661)\n    {\n        _2668 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2668 = _2661;\n    }\n    if (_2668)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2681 = fa_light_texel(param);\n    float _2682 = _2681.x;\n    if (_2682 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2691 = int(_2682 + 0.5);\n    int param_1 = _2691;\n    vec4 _2695 = fa_light_texel(param_1);\n    int param_2 = _2691 + 1;\n    vec4 _2700 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2703 = _2695.y;\n    if (_2703 > 0.0)\n    {\n        float _2720 = 1.0 - smoothstep(0.75 * _2703, _2703, length(world - fa_shadows[27].xyz));\n        fade = _2720;\n        if (_2720 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2695.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2744 = (_2691 + 2) + (face * 6);\n    int param_4 = _2744;\n    int param_5 = _2744 + 1;\n    int param_6 = _2744 + 3;\n    vec4 _2758 = fa_light_texel(param_6);\n    int param_7 = _2744 + 4;\n    vec4 _2763 = fa_light_texel(param_7);\n    int param_8 = _2744 + 5;\n    vec4 _2768 = fa_light_texel(param_8);\n    float _2780 = _2768.x * max(dot(_2758, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2785 = clamp(dot(n, l), 0.0, 1.0);\n    float _2808 = clamp(dot(n, _2758.xyz), -1.0, 1.0);\n    float _2827 = min(sqrt(1.0 - (_2808 * _2808)) / max(abs(dot(n, world - lpos)) / max(dot(_2758, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2830 = _2700.y;\n    float _2832;\n    if (_2830 > 0.0)\n    {\n        _2832 = _2830;\n    }\n    else\n    {\n        _2832 = 1.5 * _2780;\n    }\n    vec4 _2852 = vec4(world + (n * (_2832 * sqrt(1.0 - (_2785 * _2785)))), 1.0);\n    float _2856 = dot(_2758, _2852);\n    float _2859 = _2768.y;\n    if (_2856 < _2859)\n    {\n        return 1.0;\n    }\n    vec2 _2874 = vec2(dot(fa_light_texel(param_4), _2852), dot(fa_light_texel(param_5), _2852)) / vec2(_2856);\n    float _2876 = _2874.x;\n    bool _2879 = _2876 < _2763.x;\n    bool _2888;\n    if (!_2879)\n    {\n        _2888 = _2876 > _2763.z;\n    }\n    else\n    {\n        _2888 = _2879;\n    }\n    bool _2897;\n    if (!_2888)\n    {\n        _2897 = _2874.y < _2763.y;\n    }\n    else\n    {\n        _2897 = _2888;\n    }\n    bool _2906;\n    if (!_2897)\n    {\n        _2906 = _2874.y > _2763.w;\n    }\n    else\n    {\n        _2906 = _2897;\n    }\n    if (_2906)\n    {\n        return 1.0;\n    }\n    float _2912 = _2700.x;\n    float _2914;\n    if (_2912 > 0.0)\n    {\n        _2914 = _2912;\n    }\n    else\n    {\n        _2914 = 1.5 * _2780;\n    }\n    vec2 param_9 = _2874;\n    vec4 param_10 = _2763;\n    float param_11 = _2856 - (_2914 * (1.0 + (0.5 * _2827)));\n    float param_12 = _2780;\n    float param_13 = 1.0;\n    float param_14 = _2768.z * 0.25;\n    float param_15 = (_2780 * min(_2827, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2859, _2768.z);\n    int param_17 = int(_2695.z + 0.5);\n    float param_18 = _2695.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4469 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4476;\n    if (!_4469)\n    {\n        _4476 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4476 = _4469;\n    }\n    if (_4476)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4489 = fa_light_texel(param);\n    float _4490 = _4489.y;\n    float len = _4490;\n    if (_4490 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4502 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4512 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4502);\n    if (_4512 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4518 = len;\n    float _4521 = min(_4518, 0.89999997615814208984375 * dist);\n    len = _4521;\n    float _4526 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4502);\n    float _4531 = _4526 + (0.5 * _4521);\n    vec3 _4537 = world + (gn * _4526);\n    float _4539 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4603;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4554 = (float(k) + _4539) * 0.083333335816860198974609375;\n        vec3 _4562 = _4537 + (l * (_4554 * len));\n        vec4 _4568 = vec4(_4562, 1.0);\n        float _4574 = dot(fa_mesh_fs_params[28], _4568);\n        if (_4574 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4594 = vec2(dot(fa_mesh_fs_params[26], _4568), dot(fa_mesh_fs_params[27], _4568)) / vec2(_4574);\n        float _4598 = _4594.x * 0.5;\n        float _4599 = _4598 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4603 = (_4594.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4603 = 0.5 - (_4594.y * 0.5);\n        }\n        bool _4619 = _4599 < 0.0;\n        bool _4626;\n        if (!_4619)\n        {\n            _4626 = _4599 >= 1.0;\n        }\n        else\n        {\n            _4626 = _4619;\n        }\n        bool _4633;\n        if (!_4626)\n        {\n            _4633 = _4603 < 0.0;\n        }\n        else\n        {\n            _4633 = _4626;\n        }\n        bool _4640;\n        if (!_4633)\n        {\n            _4640 = _4603 >= 1.0;\n        }\n        else\n        {\n            _4640 = _4633;\n        }\n        if (_4640)\n        {\n            break;\n        }\n        vec4 _4659 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_4599, _4603) * fa_mesh_fs_params[24].zw), 0);\n        if (_4659.w < 0.5)\n        {\n            continue;\n        }\n        float _4678 = (dot(fa_mesh_fs_params[29].xyz, _4562) + fa_mesh_fs_params[29].w) - _4659.x;\n        if ((_4678 > _4526) && (_4678 < _4531))\n        {\n            occ = max(occ, (1.0 - (_4554 * _4554)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4599, 0.5 - _4598), min(_4603, 1.0 - _4603))));\n        }\n    }\n    return 1.0 - (occ * _4512);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4781 = fa_baked_keep(param);\n    if (_4781 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4807 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _7203 = _4807.color;\n    float _7204 = _4807.attenuation;\n    float _7205 = _4807.shadow;\n    bool _4810 = _4807.type == 0;\n    if (_4810 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4807.direction;\n        float _4821 = fa_shadow_factor(param_5, param_6);\n        _7205 = _4821;\n        _7203 *= _4821;\n    }\n    else\n    {\n        bool _4832 = _4807.type != 0;\n        bool _4838;\n        if (_4832)\n        {\n            _4838 = _7204 > 0.0;\n        }\n        else\n        {\n            _4838 = _4832;\n        }\n        if (_4838)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4807.direction;\n            float _4857 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7205 = _4857;\n            _7203 *= _4857;\n        }\n    }\n    bool _4867 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4873;\n    if (_4867)\n    {\n        _4873 = _7204 > 0.0;\n    }\n    else\n    {\n        _4873 = _4867;\n    }\n    if (_4873)\n    {\n        float _4880;\n        if (_4810)\n        {\n            _4880 = 1000000000.0;\n        }\n        else\n        {\n            _4880 = _4807._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4807.direction;\n        float param_18 = _4880;\n        float _4898 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7205 *= _4898;\n        _7203 *= _4898;\n    }\n    float _4911 = _7204;\n    float _4912 = _4911 * _4781;\n    _7204 = _4912;\n    return LightSample(_4807.direction, _7203, _4912, _7205, _4807._distance, _4807.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _4946 = v - (n * dot(v, n));\n    vec3 t = _4946;\n    float _4950 = dot(_4946, _4946);\n    float l2 = _4950;\n    if (_4950 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _4960;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _4960 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _4960 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _4960;\n        l2 = dot(_4960, _4960);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _4995 = dot(a, a);\n    float _4999 = dot(b, b);\n    if ((_4995 < 1.0000000195414813782625560981111e-24) || (_4999 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _5013 = a * inversesqrt(_4995);\n    vec3 _5018 = b * inversesqrt(_4999);\n    float _5022 = dot(_5013, _5018);\n    float _5025 = abs(_5022);\n    float g = (((((((((((0.0416471660137176513671875 * _5025) - 0.1924748718738555908203125) * _5025) + 0.4179156124591827392578125) * _5025) - 0.616057217121124267578125) * _5025) + 0.777722418308258056640625) * _5025) - 0.999542415142059326171875) * _5025) + 1.570791721343994140625;\n    if (_5022 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_5022 * _5022), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_5013, _5018) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _5082 = a.z > 0.0;\n    bool _5086 = b.z > 0.0;\n    if (_5082 && _5086)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5082 != _5086)\n        {\n            vec3 _5121 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5121.z = 0.0;\n            if (_5082)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _5121;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5121;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _5121;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5121;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _5170 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _5196 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _5222 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _5248 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _5170;\n    vec3 param_1 = _5196;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _5196;\n    vec3 param_7 = _5222;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _5222;\n    vec3 param_13 = _5248;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _5248;\n    vec3 param_19 = _5170;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _5398 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5422 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5438 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _5398;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _5422;\n    vec4 param_9 = m;\n    vec3 param_10 = _5398;\n    vec3 param_11 = _5422;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _5438;\n    vec4 param_14 = m;\n    vec3 param_15 = _5398;\n    vec3 param_16 = _5438;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5496 = fa_light_base(param);\n    int param_1 = _5496;\n    int param_2 = _5496 + 1;\n    int param_3 = _5496 + 2;\n    int param_4 = _5496 + 4;\n    vec4 _5518 = fa_light_texel(param_4);\n    int param_5 = _5496 + 5;\n    vec4 _5523 = fa_light_texel(param_5);\n    int param_6 = _5496 + 6;\n    vec4 _5528 = fa_light_texel(param_6);\n    float _5529 = _5528.w;\n    vec3 _5534 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5536 = _5529 < 1.5;\n    bool _5543;\n    if (_5536)\n    {\n        _5543 = dot(normalize(fa_light_texel(param_3).xyz), _5534) >= 0.0;\n    }\n    else\n    {\n        _5543 = _5536;\n    }\n    if (_5543)\n    {\n        return vec3(0.0);\n    }\n    bool _5552 = (_5529 > 0.5) && _5536;\n    float _5556 = _5552 ? 1.0539000034332275390625 : 1.0;\n    vec3 _5559 = _5518.xyz;\n    float _5561 = _5518.w;\n    vec3 _5567 = _5523.xyz;\n    float _5569 = _5523.w;\n    vec3 up = _5567 * (_5569 * _5556);\n    float _5575;\n    if (_5552)\n    {\n        _5575 = (3.1415927410125732421875 * _5561) * _5561;\n    }\n    else\n    {\n        _5575 = (4.0 * _5561) * _5569;\n    }\n    if (_5529 > 1.5)\n    {\n        vec3 _5601 = cross(_5559, -_5534);\n        vec3 perp = _5601;\n        float _5605 = dot(_5601, _5601);\n        vec3 _5608;\n        if (_5605 > 1.0000000133514319600180897396058e-10)\n        {\n            _5608 = perp * inversesqrt(_5605);\n        }\n        else\n        {\n            _5608 = _5567;\n        }\n        perp = _5608;\n        up = _5608 * _5569;\n    }\n    float _5629 = max(_5575, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _5639 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _5639;\n    vec3 param_10 = n;\n    vec3 param_11 = _5534;\n    vec3 _5647 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _5639;\n    vec3 param_13 = n;\n    vec3 param_14 = _5559 * (_5561 * _5556);\n    vec3 _5655 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _5639;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _5663 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _5529;\n    vec3 param_20 = _5647;\n    vec3 param_21 = _5655;\n    vec3 param_22 = _5663;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _5682 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _5682;\n    vec2 param_26 = _5682 + vec2(64.0, 0.0);\n    vec4 _5692 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5529;\n    vec3 param_29 = _5647;\n    vec3 param_30 = _5655;\n    vec3 param_31 = _5663;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5692.x) + ((vec3(f90) - f0) * _5692.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_5534, _5534)) + _5629) / _5629) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4206 = 1.0 / alpha;\n    return ((2.0 + _4206) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4206)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4241 = max(dot(L.nc, l), 0.0);\n    float _4247 = max(dot(L.nc, h), 0.0);\n    float _4256 = ((_4247 * _4247) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4256) * _4256)) * (0.5 / max(mix((2.0 * _4241) * L.coat_ndv, _4241 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4241)) * _4241;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5760;\n    if (L.sheen_on)\n    {\n        _5760 = L.sheen_scale;\n    }\n    else\n    {\n        _5760 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5760);\n    vec3 _5773 = normalize(l + v);\n    int param_10 = li;\n    vec3 _5784 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5793 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5773), 0.0);\n        float param_13 = _5793;\n        float param_14 = ndv;\n        result += ((L.sheen * _5784) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _5793)) * _5793) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _5773;\n        float param_18 = max(dot(v, _5773), 0.0);\n        result += (_5784 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4109 = tdh / at;\n    float _4113 = bdh / ab;\n    float _4125 = ((_4109 * _4109) + (_4113 * _4113)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4125) * _4125);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4305 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4384 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _4384) * _4384);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4305);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4305));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3515 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3518 = _3515.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3518 * _3518, exp2((-9.27999973297119140625) * ndv)) * _3518) + _3515.y)) + _3515.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3369 = rough * rough;\n    float _3399 = 0.60000002384185791015625 * _3369;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3369)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3399, 0.0500000007450580596923828125 + _3399, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3369 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3992;\n        if (L.aniso >= 0.0)\n        {\n            _3992 = L.b;\n        }\n        else\n        {\n            _3992 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3992, v), _3992), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4025 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4025.x) + (vec3(L.f90) * _4025.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4080 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4080.x) + _4080.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3557 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3557.x) + vec3(_3557.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3163 = int(fa_shadows[25].x + 0.5);\n    float _3173 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3178 = _3163 > 0;\n    bool _3187;\n    if (_3178)\n    {\n        int param = _3163 - 1;\n        _3187 = _3173 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3187 = _3178;\n    }\n    if (_3187)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3193 = _3163 > 1;\n        bool _3200;\n        if (_3193)\n        {\n            _3200 = _3173 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3200 = _3193;\n        }\n        if (_3200)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3206 = _3163 > 2;\n        bool _3213;\n        if (_3206)\n        {\n            _3213 = _3173 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3213 = _3206;\n        }\n        if (_3213)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3219 = _3163 > 3;\n        bool _3226;\n        if (_3219)\n        {\n            _3226 = _3173 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3226 = _3219;\n        }\n        if (_3226)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _6903 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6903 = -_6903;\n    }\n    vec3 _6266 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6903, fa_world_tangent, fa_uv, fa_vertex_color, _6266, gl_FrontFacing);\n    Surface _6274 = fa_standard_surface(param_1);\n    vec3 _6934 = _6274.albedo;\n    float _6935 = _6274.alpha;\n    vec3 _6936 = _6274.normal;\n    float _6937 = _6274.metallic;\n    float _6938 = _6274.roughness;\n    float _6939 = _6274.occlusion;\n    vec3 _6940 = _6274.emission;\n    float _6941 = _6274.clearcoat;\n    float _6942 = _6274.clearcoat_roughness;\n    vec3 _6943 = _6274.sheen_color;\n    float _6944 = _6274.sheen_roughness;\n    float _6945 = _6274.anisotropy;\n    float _6946 = _6274.anisotropy_rotation;\n    float _6947 = _6274.specular;\n    float _6948 = _6274.ior;\n    vec3 _6949 = _6274.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6903, fa_world_tangent, fa_uv, fa_vertex_color, _6266, gl_FrontFacing);\n    Surface param_3 = _6274;\n    surface(param_2, param_3);\n    _6934 = param_3.albedo;\n    _6935 = param_3.alpha;\n    _6936 = param_3.normal;\n    _6937 = param_3.metallic;\n    _6938 = param_3.roughness;\n    _6939 = param_3.occlusion;\n    _6940 = param_3.emission;\n    _6941 = param_3.clearcoat;\n    _6942 = param_3.clearcoat_roughness;\n    _6943 = param_3.sheen_color;\n    _6944 = param_3.sheen_roughness;\n    _6945 = param_3.anisotropy;\n    _6946 = param_3.anisotropy_rotation;\n    _6947 = param_3.specular;\n    _6948 = param_3.ior;\n    _6949 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6903;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6934 = param_6;\n    _6936 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6934;\n    }\n    else\n    {\n        vec3 _6313 = normalize(_6936);\n        float _6320 = clamp(_6937, 0.0, 1.0);\n        float _6324 = clamp(_6938, 0.0500000007450580596923828125, 1.0);\n        float _6328 = _6324 * _6324;\n        float _6332 = _6328 * _6328;\n        float _6337 = max(dot(_6313, _6266), 9.9999997473787516355514526367188e-05);\n        vec3 _6343 = _6934 * (1.0 - _6320);\n        vec3 _6350 = mix(vec3(0.039999999105930328369140625), _6934, vec3(_6320));\n        vec3 f0 = _6350;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _6903, fa_world_tangent, fa_uv, fa_vertex_color, _6266, gl_FrontFacing);\n        Surface param_9 = Surface(_6934, _6935, _6936, _6937, _6938, _6939, _6940, _6941, _6942, _6943, _6944, _6945, _6946, _6947, _6948, _6949);\n        vec3 param_10 = _6313;\n        vec3 param_11 = _6266;\n        float param_12 = _6320;\n        float param_13 = _6324;\n        vec3 param_14 = _6350;\n        FaLayers _6366 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _6313;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _6343) * _6939;\n        if (_6366.on)\n        {\n            lit *= _6366.base_scale;\n        }\n        int _6388 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6388; ln++)\n        {\n            int param_16 = ln;\n            int _6401 = fa_cl_light(param_16);\n            int param_17 = _6401;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _6401;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _6903;\n            LightSample _6417 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6425 = max(dot(_6313, _6417.direction), 0.0);\n            float _6431 = _6417.attenuation * _6417.shadow;\n            vec3 _6436 = normalize(_6417.direction + _6266);\n            float _6441 = max(dot(_6313, _6436), 0.0);\n            float _6446 = max(dot(_6266, _6436), 0.0);\n            bool _6453;\n            if (fa_light_is_area)\n            {\n                _6453 = !_6366.on;\n            }\n            else\n            {\n                _6453 = fa_light_is_area;\n            }\n            if (_6453)\n            {\n                int param_21 = _6401;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _6313;\n                vec3 param_24 = _6266;\n                vec3 param_25 = _6343;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _6324;\n                float param_29 = _6337;\n                float param_30 = _6431;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6366;\n                    int param_32 = _6401;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _6313;\n                    vec3 param_35 = _6266;\n                    vec3 param_36 = _6417.direction;\n                    vec3 param_37 = _6343;\n                    vec3 param_38 = f0;\n                    float param_39 = _6324;\n                    float param_40 = _6337;\n                    float param_41 = _6431;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6366.on)\n                    {\n                        FaLayers param_42 = _6366;\n                        vec3 param_43 = _6343;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _6313;\n                        vec3 param_46 = _6266;\n                        vec3 param_47 = _6417.direction;\n                        vec3 param_48 = _6436;\n                        float param_49 = _6425;\n                        float param_50 = _6337;\n                        float param_51 = _6441;\n                        float param_52 = _6446;\n                        float param_53 = _6328;\n                        float param_54 = _6332;\n                        int param_55 = _6401;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6431));\n                    }\n                    else\n                    {\n                        float _6559 = ((_6441 * _6441) * (_6332 - 1.0)) + 1.0;\n                        int param_56 = _6401;\n                        lit += (((_6343 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _6446, 5.0))) * (((_6332 / ((3.1415927410125732421875 * _6559) * _6559)) * (0.5 / max(mix((2.0 * _6425) * _6337, _6425 + _6337, _6328), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _6425))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6425 * _6431));\n                    }\n                }\n            }\n        }\n        if (_6366.on)\n        {\n            FaLayers param_57 = _6366;\n            vec3 param_58 = _6313;\n            vec3 param_59 = _6266;\n            vec3 param_60 = f0;\n            float param_61 = _6324;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6939);\n        }\n        else\n        {\n            vec3 param_62 = _6313;\n            vec3 param_63 = _6266;\n            vec3 param_64 = f0;\n            float param_65 = _6324;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6939);\n        }\n        result = lit;\n    }\n    vec3 _6654 = result;\n    vec3 _6655 = _6654 + _6940;\n    result = _6655;\n    vec3 param_66 = _6655;\n    vec3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6664 = fa_mesh_fs_params[7].w > 0.0;\n    bool _6671;\n    if (!_6664)\n    {\n        _6671 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _6671 = _6664;\n    }\n    if (_6671)\n    {\n        vec3 _6680 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6686 = dot(_6680, fa_mesh_fs_params[9].xyz);\n        bool _6690 = fa_mesh_fs_params[9].w > 0.5;\n        float _6691;\n        if (_6690)\n        {\n            _6691 = _6686;\n        }\n        else\n        {\n            _6691 = length(_6680);\n        }\n        float _6703 = _6691 - fa_mesh_fs_params[8].x;\n        if (_6703 > 0.0)\n        {\n            float _6712 = fa_mesh_fs_params[7].w * _6703;\n            float tau = _6712 * _6712;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6728;\n                if (_6690)\n                {\n                    _6728 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6686);\n                }\n                else\n                {\n                    _6728 = fa_mesh_fs_params[0].y;\n                }\n                float _6749 = mix(_6728, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6691, 0.0, 1.0));\n                float _6753 = fa_world_pos.y - _6749;\n                float _6758 = _6749 - fa_mesh_fs_params[8].z;\n                float _6763 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6766 = _6758 <= 0.0;\n                bool _6767 = !_6766;\n                bool _6773;\n                if (_6767)\n                {\n                    _6773 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6773 = _6766;\n                }\n                float _6774;\n                if (_6773)\n                {\n                    _6774 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6774 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6758, 80.0));\n                }\n                bool _6801;\n                if (_6767)\n                {\n                    _6801 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6801 = _6766;\n                }\n                float _6802;\n                if (_6801)\n                {\n                    _6802 = fa_mesh_fs_params[8].y * _6758;\n                }\n                else\n                {\n                    _6802 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6758, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6827 = _6763 <= 0.0;\n                bool _6834;\n                if (!_6827)\n                {\n                    _6834 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6834 = _6827;\n                }\n                float _6835;\n                if (_6834)\n                {\n                    _6835 = fa_mesh_fs_params[8].y * _6763;\n                }\n                else\n                {\n                    _6835 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6763, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _6862;\n                if (abs(_6753) < 0.001000000047497451305389404296875)\n                {\n                    _6862 = _6774;\n                }\n                else\n                {\n                    _6862 = (_6835 - _6802) / _6753;\n                }\n                tau += (_6703 * max(_6862, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6935);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_joints"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_weights"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_183",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 192,
                "offset": 0,
                "glsl_name": "fa_skin"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_560",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 39,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2227",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
                "offset": 0,
                "glsl_name": "fa_shadows"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering"
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1,
            "glsl_name": "fa_light_tex_fa_shadow_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10,
            "glsl_name": "fa_decal_tex_fa_env_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10,
            "glsl_name": "fa_lightmap_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _299 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[39];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _197 = fa_linear_to_srgb(param);\n        c = _197;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _205 = fa_srgb_to_linear(param_1);\n            c = _205;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _245 = fa_tex_fix(param_2, param_3);\n    vec4 _754 = base_t;\n    _754.x = _245.x;\n    _754.y = _245.y;\n    _754.z = _245.z;\n    base_t = _754;\n    vec4 _261 = (_754 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _717 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _295 = fa_tex_fix(param_6, param_7);\n        vec3 _299 = (_295 * 2.0) - vec3(1.0);\n        vec2 _304 = _299.xy * fa_mesh_fs_params[6].x;\n        vec3 _762 = _299;\n        _762.x = _304.x;\n        _762.y = _304.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _762;\n        _717 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _333 = fa_tex_fix(param_12, param_13);\n    vec4 _765 = mrt;\n    _765.x = _333.x;\n    _765.y = _333.y;\n    _765.z = _333.z;\n    mrt = _765;\n    vec4 _363 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _363.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _375 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _405 = fa_tex_fix(param_20, param_21);\n    float _722 = fa_mesh_fs_params[20].x;\n    float _723 = fa_mesh_fs_params[20].y;\n    float _726 = fa_mesh_fs_params[20].z;\n    float _725 = fa_mesh_fs_params[21].w;\n    float _728 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _722 *= _375.y;\n            _723 *= _375.z;\n            _725 *= _363.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _726 *= mrt.x;\n            _728 *= mrt.w;\n        }\n    }\n    return Surface(_261.xyz, _261.w, _717, clamp(fa_mesh_fs_params[5].x * _333.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _333.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_375.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _405), _722, _723, fa_mesh_fs_params[21].xyz, _725, _726, fa_mesh_fs_params[20].w, _728, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += vec3(0.5 + (0.5 * sin(fa_mesh_fs_params[13].x * 3.0)), 0.25 * fract(fa_mesh_fs_params[13].x), 0.0);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _628 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _628 = -_628;\n    }\n    vec3 _538 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _628, fa_world_tangent, fa_uv, fa_vertex_color, _538, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _628, fa_world_tangent, fa_uv, fa_vertex_color, _538, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _553 = normalize(param_2.normal);\n    vec3 _568 = normalize(vec3(dot(fa_pre_r0, _553), dot(fa_pre_r1, _553), dot(fa_pre_r2, _553)));\n    float _580 = _568.z;\n    vec2 e = _568.xy / vec2((abs(_568.x) + abs(_568.y)) + abs(_580));\n    if (_580 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_127",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 39,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _420 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[39];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _197 = fa_linear_to_srgb(param);\n        c = _197;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _205 = fa_srgb_to_linear(param_1);\n            c = _205;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _245 = fa_tex_fix(param_2, param_3);\n    vec4 _754 = base_t;\n    _754.x = _245.x;\n    _754.y = _245.y;\n    _754.z = _245.z;\n    base_t = _754;\n    vec4 _261 = (_754 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _717 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _295 = fa_tex_fix(param_6, param_7);\n        vec3 _299 = (_295 * 2.0) - vec3(1.0);\n        vec2 _304 = _299.xy * fa_mesh_fs_params[6].x;\n        vec3 _762 = _299;\n        _762.x = _304.x;\n        _762.y = _304.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _762;\n        _717 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _333 = fa_tex_fix(param_12, param_13);\n    vec4 _765 = mrt;\n    _765.x = _333.x;\n    _765.y = _333.y;\n    _765.z = _333.z;\n    mrt = _765;\n    vec4 _363 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _363.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _375 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _405 = fa_tex_fix(param_20, param_21);\n    float _722 = fa_mesh_fs_params[20].x;\n    float _723 = fa_mesh_fs_params[20].y;\n    float _726 = fa_mesh_fs_params[20].z;\n    float _725 = fa_mesh_fs_params[21].w;\n    float _728 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _722 *= _375.y;\n            _723 *= _375.z;\n            _725 *= _363.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _726 *= mrt.x;\n            _728 *= mrt.w;\n        }\n    }\n    return Surface(_261.xyz, _261.w, _717, clamp(fa_mesh_fs_params[5].x * _333.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _333.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_375.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _405), _722, _723, fa_mesh_fs_params[21].xyz, _725, _726, fa_mesh_fs_params[20].w, _728, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += vec3(0.5 + (0.5 * sin(fa_mesh_fs_params[13].x * 3.0)), 0.25 * fract(fa_mesh_fs_params[13].x), 0.0);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _628 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _628 = -_628;\n    }\n    vec3 _538 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _628, fa_world_tangent, fa_uv, fa_vertex_color, _538, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _628, fa_world_tangent, fa_uv, fa_vertex_color, _538, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _553 = normalize(param_2.normal);\n    vec3 _568 = normalize(vec3(dot(fa_pre_r0, _553), dot(fa_pre_r1, _553), dot(fa_pre_r2, _553)));\n    float _580 = _568.z;\n    vec2 e = _568.xy / vec2((abs(_568.x) + abs(_568.y)) + abs(_580));\n    if (_580 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_joints"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_weights"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_183",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 192,
                "offset": 0,
                "glsl_name": "fa_skin"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_127",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 39,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          }
        ]
      }
    }
  }
}
