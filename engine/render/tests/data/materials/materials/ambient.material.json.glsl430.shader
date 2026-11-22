{
  "format": "factoria.shader/1",
  "engine": "0.34.0",
  "template": "d5ad4ba00a2086cd5c3d6440d2be629e3ce9b0f8ede644c9a19112677c2fea28",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1388 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1395;\n    if (!_1388)\n    {\n        _1395 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1395 = _1388;\n    }\n    bool _1403;\n    if (!_1395)\n    {\n        _1403 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1403 = _1395;\n    }\n    bool _1410;\n    if (!_1403)\n    {\n        _1410 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1410 = _1403;\n    }\n    bool _1417;\n    if (!_1410)\n    {\n        _1417 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1417 = _1410;\n    }\n    if (_1417)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1427 = vec4(world_pos, 1.0);\n    float _1433 = dot(fa_mesh_fs_params[16], _1427);\n    if (!(_1433 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1455 = vec2(dot(fa_mesh_fs_params[14], _1427), dot(fa_mesh_fs_params[15], _1427)) / vec2(_1433);\n    int _1459 = int(fa_mesh_fs_params[18].x);\n    int _1463 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1463) + clamp(int(floor(((_1455.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1463 - 1)) * _1459)) + clamp(int(floor(((_1455.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1459 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1539 = fa_cluster_texel(param);\n    return ivec2(int(_1539.x), int(_1539.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3788 = fa_cluster_lookup(param);\n    fa_cl_slot = _3788.x;\n    fa_cl_local = _3788.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3998 = fa_linear_to_srgb(param);\n        c = _3998;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4006 = fa_srgb_to_linear(param_1);\n            c = _4006;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _304;\n    if (i.front_facing)\n    {\n        _304 = i.world_normal;\n    }\n    else\n    {\n        _304 = -i.world_normal;\n    }\n    vec3 _328 = normalize(i.world_tangent.xyz - (_304 * dot(_304, i.world_tangent.xyz)));\n    vec3 _355 = normalize(((_328 * m.x) + ((cross(_304, _328) * i.world_tangent.w) * m.y)) + (_304 * m.z));\n    vec3 _358;\n    if (i.front_facing)\n    {\n        _358 = _355;\n    }\n    else\n    {\n        _358 = -_355;\n    }\n    return _358;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4037 = fa_tex_fix(param_2, param_3);\n    vec4 _5838 = base_t;\n    _5838.x = _4037.x;\n    _5838.y = _4037.y;\n    _5838.z = _4037.z;\n    base_t = _5838;\n    vec4 _4051 = (_5838 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _5675 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4083 = fa_tex_fix(param_6, param_7);\n        vec3 _4086 = (_4083 * 2.0) - vec3(1.0);\n        vec2 _4091 = _4086.xy * fa_mesh_fs_params[6].x;\n        vec3 _5846 = _4086;\n        _5846.x = _4091.x;\n        _5846.y = _4091.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5846;\n        _5675 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4119 = fa_tex_fix(param_12, param_13);\n    vec4 _5849 = mrt;\n    _5849.x = _4119.x;\n    _5849.y = _4119.y;\n    _5849.z = _4119.z;\n    mrt = _5849;\n    vec4 _4147 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4147.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4158 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4188 = fa_tex_fix(param_20, param_21);\n    float _5680 = fa_mesh_fs_params[20].x;\n    float _5681 = fa_mesh_fs_params[20].y;\n    float _5684 = fa_mesh_fs_params[20].z;\n    float _5683 = fa_mesh_fs_params[21].w;\n    float _5686 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _5680 *= _4158.y;\n            _5681 *= _4158.z;\n            _5683 *= _4147.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _5684 *= mrt.x;\n            _5686 *= mrt.w;\n        }\n    }\n    return Surface(_4051.xyz, _4051.w, _5675, clamp(fa_mesh_fs_params[5].x * _4119.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4119.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4158.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4188), _5680, _5681, fa_mesh_fs_params[21].xyz, _5683, _5684, fa_mesh_fs_params[20].w, _5686, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1619 = rect.zw - rect.xy;\n    vec2 _1623 = _1619 * atlas;\n    vec2 _1627 = ddx * _1623;\n    vec2 _1631 = ddy * _1623;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1619), clamp(0.5 * log2(max(max(dot(_1627, _1627), dot(_1631, _1631)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1664 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1671;\n    if (!_1664)\n    {\n        _1671 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1671 = _1664;\n    }\n    if (_1671)\n    {\n        return;\n    }\n    vec3 _1677 = dFdx(world_pos);\n    vec3 _1680 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1684 = fa_cluster_texel(param);\n    int _1688 = int(_1684.w);\n    if (_1688 < 1)\n    {\n        return;\n    }\n    int _1698 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1698;\n    vec4 _1702 = fa_light_texel(param_1);\n    vec2 _1705 = _1702.yz;\n    int _1709 = int(_1702.w);\n    int param_2 = _1698 + 1;\n    vec4 _1714 = fa_light_texel(param_2);\n    float _1715 = _1714.x;\n    int _1721 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1725 = int(_1684.z);\n    vec3 _1990;\n    for (int k = 0; k < _1688; k++)\n    {\n        int _1738 = _1725 + k;\n        int param_3 = _1709 + (_1738 >> 2);\n        int _1755 = (_1698 + 2) + (int(fa_light_texel(param_3)[_1738 & 3]) * 7);\n        int param_4 = _1755 + 6;\n        vec4 _1760 = fa_light_texel(param_4);\n        if (((int(_1760.w + 0.5) >> _1721) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1755;\n        vec4 _1775 = fa_light_texel(param_5);\n        int param_6 = _1755 + 1;\n        vec4 _1780 = fa_light_texel(param_6);\n        int param_7 = _1755 + 2;\n        vec4 _1785 = fa_light_texel(param_7);\n        vec3 _1788 = _1775.xyz;\n        float _1793 = dot(_1788, world_pos) + _1775.w;\n        vec3 _1795 = _1780.xyz;\n        float _1800 = dot(_1795, world_pos) + _1780.w;\n        vec3 _1802 = _1785.xyz;\n        float _1807 = dot(_1802, world_pos) + _1785.w;\n        bool _1812 = abs(_1793) > 0.5;\n        bool _1820;\n        if (!_1812)\n        {\n            _1820 = abs(_1800) > 0.5;\n        }\n        else\n        {\n            _1820 = _1812;\n        }\n        bool _1828;\n        if (!_1820)\n        {\n            _1828 = abs(_1807) > 0.5;\n        }\n        else\n        {\n            _1828 = _1820;\n        }\n        if (_1828)\n        {\n            continue;\n        }\n        float _1843 = clamp(dot(geo_normal, normalize(_1802)) * _1760.z, 0.0, 1.0);\n        if (_1843 <= 0.0)\n        {\n            continue;\n        }\n        float _1863 = (clamp((0.5 - abs(_1807)) * 10.0, 0.0, 1.0) * _1843) * _1760.x;\n        vec2 _1871 = vec2(_1793 + 0.5, 0.5 - _1800);\n        vec2 _1881 = vec2(dot(_1788, _1677), dot(_1795, _1677));\n        vec2 _1891 = vec2(dot(_1788, _1680), dot(_1795, _1680));\n        int param_8 = _1755 + 5;\n        vec4 _1896 = fa_light_texel(param_8);\n        int param_9 = _1755 + 3;\n        vec4 _1901 = fa_light_texel(param_9);\n        int param_10 = _1755 + 4;\n        vec4 _1906 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1896.xyz;\n        bool _1916 = _1901.z > _1901.x;\n        if (_1916)\n        {\n            vec4 param_11 = _1901;\n            vec2 param_12 = _1871;\n            vec2 param_13 = _1705;\n            vec2 param_14 = _1881;\n            vec2 param_15 = _1891;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1715 > 0.5) && (_1715 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1942 = fa_dc_to_linear(param_16);\n                vec4 _5763 = tx;\n                _5763.x = _1942.x;\n                _5763.y = _1942.y;\n                _5763.z = _1942.z;\n                tx = _5763;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1863 * tex_a) * _1896.w, 0.0, 1.0)));\n        if (_1906.z > _1906.x)\n        {\n            vec4 param_17 = _1906;\n            vec2 param_18 = _1871;\n            vec2 param_19 = _1705;\n            vec2 param_20 = _1881;\n            vec2 param_21 = _1891;\n            vec4 _1986 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1715 > 1.5)\n            {\n                vec3 param_22 = _1986.xyz;\n                vec3 _1996 = fa_dc_to_srgb(param_22);\n                _1990 = _1996;\n            }\n            else\n            {\n                _1990 = _1986.xyz;\n            }\n            vec3 _2005 = (_1990 * 2.0) - vec3(1.0);\n            vec2 _2010 = _2005.xy * _1760.y;\n            vec3 _2032 = (normalize(_1788) * _2010.x) + (normalize(_1795) * _2010.y);\n            vec3 _2035 = normalize(normal);\n            normal = normalize(mix(_2035, normalize((_2035 * max(_2005.z, 0.0500000007450580596923828125)) + (_2032 - (_2035 * dot(_2035, _2032)))), vec3(clamp(_1863 * (_1916 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _394 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _397;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _397 = _394 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _397 = _394 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_397)\n        {\n            discard;\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3242 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3242;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3352 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3358 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3352 > 0.0005000000237487256526947021484375)\n    {\n        if (_3358)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3352;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3352;\n        }\n    }\n    bool _3410 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3410)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _3441 = fa_mesh_fs_params[47].w > 0.0;\n    if (_3441)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3358 || _3410) || _3441)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3262 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3265 = _3262.x;\n    float _3267 = _3262.z;\n    vec2 e = vec2(_3265, _3267);\n    if (_3262.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3267)) * ((_3265 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3265)) * ((_3267 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _4302 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _4307 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _4312 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _4317 = fa_light_texel(param_3);\n    bool _4320 = _4317.z < 0.5;\n    bool _4328;\n    if (!_4320)\n    {\n        _4328 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _4328 = _4320;\n    }\n    if (_4328)\n    {\n        return vec3(0.0);\n    }\n    float _4335 = max(_4302.w, 9.9999997473787516355514526367188e-05);\n    vec3 _4338 = _4307.xyz;\n    vec3 _4342 = _4302.xyz;\n    vec3 _4346 = (fa_world_pos - _4342) / vec3(_4335);\n    vec3 _4355 = min(_4346 + vec3(0.5), (_4338 - vec3(0.5)) - _4346);\n    float _4364 = min(_4355.x, min(_4355.y, _4355.z));\n    if (!(_4364 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4379 = _4338 - vec3(1.0);\n    vec3 _4380 = clamp(_4346, vec3(0.0), _4379);\n    vec3 _4388 = min(floor(_4380), max(_4338 - vec3(2.0), vec3(0.0)));\n    vec3 _4392 = _4380 - _4388;\n    vec3 _4404 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _4335));\n    int _4409 = int(_4312.y + 0.5);\n    float _4414 = 0.3257350027561187744140625 * n.y;\n    float _4418 = 0.3257350027561187744140625 * n.z;\n    float _4422 = 0.3257350027561187744140625 * n.x;\n    float _4429 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _4436 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _4445 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _4452 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _4465 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _4472 = 8 + int(_4317.w);\n    float _4499;\n    float _4512;\n    float _4526;\n    for (int k = 0; k < _4472; k++)\n    {\n        float _4485 = float(k & 1);\n        float _4489 = float((k >> 1) & 1);\n        float _4493 = float((k >> 2) & 1);\n        if (_4485 > 0.5)\n        {\n            _4499 = _4392.x;\n        }\n        else\n        {\n            _4499 = 1.0 - _4392.x;\n        }\n        if (_4489 > 0.5)\n        {\n            _4512 = _4392.y;\n        }\n        else\n        {\n            _4512 = 1.0 - _4392.y;\n        }\n        if (_4493 > 0.5)\n        {\n            _4526 = _4392.z;\n        }\n        else\n        {\n            _4526 = 1.0 - _4392.z;\n        }\n        float _4536 = (_4499 * _4512) * _4526;\n        if (!(_4536 > 0.0))\n        {\n            continue;\n        }\n        vec3 _4549 = min(_4388 + vec3(_4485, _4489, _4493), _4379);\n        int _4569 = int(((_4312.x + _4549.x) + (_4307.x * (_4549.y + (_4307.y * _4549.z)))) + 0.5);\n        vec2 _4584 = vec2(float(_4569 % _4409) * 10.0, 1024.0 + (float(_4569 / _4409) * 11.0));\n        vec2 param_4 = _4584 + vec2(9.5, 10.5);\n        vec4 _4592 = fa_gi_fetch(param_4);\n        bool _4595 = _4592.y < 0.5;\n        bool _4604;\n        if (!_4595)\n        {\n            _4604 = _4592.x > _4317.y;\n        }\n        else\n        {\n            _4604 = _4595;\n        }\n        if (_4604)\n        {\n            continue;\n        }\n        vec3 _4616 = _4404 - (_4342 + (_4549 * _4335));\n        float _4619 = length(_4616);\n        vec3 _4625 = _4616 / vec3(max(_4619, 9.9999997473787516355514526367188e-05));\n        float _4635 = max(9.9999997473787516355514526367188e-05, (dot(-_4625, n) + 1.0) * 0.5);\n        float w = _4536 * (_4635 * _4635);\n        vec3 param_5 = _4625;\n        vec2 param_6 = (_4584 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _4655 = fa_gi_fetch(param_6);\n        float _4662 = _4619 / max(_4312.z, 9.9999997473787516355514526367188e-05);\n        float _4665 = _4655.x;\n        if (_4662 > _4665)\n        {\n            float _4678 = max(_4655.y - (_4665 * _4665), 0.0);\n            float _4683 = _4662 - _4665;\n            float _4692 = _4678 / max(_4678 + (_4683 * _4683), 9.9999999600419720025001879548654e-13);\n            w *= ((_4692 * _4692) * _4692);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _4584 + vec2(0.5, 10.5);\n        vec2 param_8 = _4584 + vec2(1.5, 10.5);\n        vec2 param_9 = _4584 + vec2(2.5, 10.5);\n        vec2 param_10 = _4584 + vec2(3.5, 10.5);\n        vec2 param_11 = _4584 + vec2(4.5, 10.5);\n        vec2 param_12 = _4584 + vec2(5.5, 10.5);\n        vec2 param_13 = _4584 + vec2(6.5, 10.5);\n        vec2 param_14 = _4584 + vec2(7.5, 10.5);\n        vec2 param_15 = _4584 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _4414)) + (fa_gi_fetch(param_9).xyz * _4418)) + (fa_gi_fetch(param_10).xyz * _4422)) + (fa_gi_fetch(param_11).xyz * _4429)) + (fa_gi_fetch(param_12).xyz * _4436)) + (fa_gi_fetch(param_13).xyz * _4445)) + (fa_gi_fetch(param_14).xyz * _4452)) + (fa_gi_fetch(param_15).xyz * _4465)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_4364 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _4819;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _4819 = _4317.x;\n    }\n    else\n    {\n        _4819 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_4312.w * _4819);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _4843 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _4848 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _4853 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _4853) && (k < 8); k++)\n    {\n        int param = _4848 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _4843;\n        vec3 _4878 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _4883 = param_3 * left;\n        acc += (_4878 * _4883);\n        left -= _4883;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _4912 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _4912;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return vec3(0.0, ambientColor.y, 0.0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3758;\n    if (fa_lm.z > 0.5)\n    {\n        _3758 = 0.0;\n    }\n    else\n    {\n        _3758 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _3769 = _3758 < 1.0;\n    bool _3775;\n    if (_3769)\n    {\n        int param = li;\n        _3775 = fa_light_baked(param);\n    }\n    else\n    {\n        _3775 = _3769;\n    }\n    return _3775 ? _3758 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _638 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _651 = (c - (ru * hx)) - p;\n        vec3 _657 = ru * (2.0 * hx);\n        float _663 = max(dot(_657, _657), 9.9999999392252902907785028219223e-09);\n        float _667 = dot(_651, _657);\n        float t = clamp((-_667) / _663, 0.0, 1.0);\n        if (_638)\n        {\n            float _682 = dot(r, _657);\n            float _688 = _663 - (_682 * _682);\n            if (abs(_688) > (9.9999997473787516355514526367188e-06 * _663))\n            {\n                t = clamp(((dot(r, _651) * _682) - _667) / _688, 0.0, 1.0);\n            }\n        }\n        return (p + _651) + (_657 * t);\n    }\n    vec3 q = p;\n    float _720 = dot(r, axis);\n    bool _728;\n    if (_638)\n    {\n        _728 = abs(_720) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _728 = _638;\n    }\n    if (_728)\n    {\n        float _738 = dot(c - p, axis) / _720;\n        if (_738 > 0.0)\n        {\n            q = p + (r * _738);\n        }\n    }\n    vec3 _751 = q - c;\n    vec2 xy = vec2(dot(_751, ru), dot(_751, uu));\n    if (shape > 0.5)\n    {\n        float _766 = length(xy);\n        if (_766 > hx)\n        {\n            xy *= (hx / _766);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _558 = dot(d, right);\n    float _562 = dot(d, up);\n    float _573;\n    if (((_558 * _558) + (_562 * _562)) > 1.0000000133514319600180897396058e-10)\n    {\n        _573 = atan(_562, _558) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _573 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_573 - floor(_573)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _414 = abs(d);\n    float _416 = _414.x;\n    float _418 = _414.y;\n    bool _419 = _416 >= _418;\n    bool _427;\n    if (_419)\n    {\n        _427 = _416 >= _414.z;\n    }\n    else\n    {\n        _427 = _419;\n    }\n    int _428;\n    if (_427)\n    {\n        _428 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _442;\n        if (_418 >= _414.z)\n        {\n            _442 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _442 = (d.z > 0.0) ? 4 : 5;\n        }\n        _428 = _442;\n    }\n    return _428;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _804 = fa_light_base(param);\n    bool _808 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _804;\n    vec4 _812 = fa_light_texel(param_1);\n    int param_2 = _804 + 1;\n    vec4 _817 = fa_light_texel(param_2);\n    float _820 = _817.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _832 = _808 && (_820 > 2.5);\n    fa_light_is_area = _832;\n    bool _834 = _820 < 0.5;\n    vec3 l;\n    if (_834)\n    {\n        l = normalize(_812.xyz);\n        if (_808)\n        {\n            int param_3 = _804 + 6;\n            vec4 _848 = fa_light_texel(param_3);\n            if (_848.z > 0.5)\n            {\n                int param_4 = _804 + 4;\n                vec4 _858 = fa_light_texel(param_4);\n                int param_5 = _804 + 5;\n                vec4 _863 = fa_light_texel(param_5);\n                vec2 param_6 = _848.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _858.xyz) * _858.w, (-dot(world_pos, _863.xyz)) * _863.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _893 = _812.xyz;\n        vec3 _895 = _893 - world_pos;\n        vec3 to_light = _895;\n        float _898 = length(_895);\n        float reach = _898;\n        bool front = true;\n        if (_832)\n        {\n            int param_8 = _804 + 7;\n            reach = max(_898 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _804 + 4;\n            vec4 _922 = fa_light_texel(param_9);\n            int param_10 = _804 + 5;\n            vec4 _927 = fa_light_texel(param_10);\n            int param_11 = _804 + 6;\n            vec4 _932 = fa_light_texel(param_11);\n            float _933 = _932.w;\n            int param_12 = _804 + 2;\n            vec3 _940 = normalize(fa_light_texel(param_12).xyz);\n            bool _942 = _933 > 1.5;\n            bool _950;\n            if (!_942)\n            {\n                _950 = dot(_940, to_light) < 0.0;\n            }\n            else\n            {\n                _950 = _942;\n            }\n            front = _950;\n            vec3 r = vec3(0.0);\n            vec3 _959 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _963 = dot(n, n) > 0.5;\n            bool _971;\n            if (_963)\n            {\n                _971 = dot(_959, _959) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _971 = _963;\n            }\n            if (_971)\n            {\n                r = reflect(-normalize(_959), normalize(n));\n            }\n            vec3 param_13 = _893;\n            vec3 param_14 = _940;\n            vec3 param_15 = _922.xyz;\n            vec3 param_16 = _927.xyz;\n            float param_17 = _922.w;\n            float param_18 = _927.w;\n            float param_19 = _933;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1007 = length(to_light);\n        dist = _1007;\n        l = to_light / vec3(max(_1007, 9.9999997473787516355514526367188e-05));\n        float _1021 = reach / max(_812.w, 0.001000000047497451305389404296875);\n        float _1027 = clamp(1.0 - (_1021 * _1021), 0.0, 1.0);\n        float _1029;\n        if (front)\n        {\n            _1029 = _1027 * _1027;\n        }\n        else\n        {\n            _1029 = 0.0;\n        }\n        atten = _1029;\n        bool _1040 = _820 < 2.5;\n        if ((_820 > 1.5) && _1040)\n        {\n            int param_22 = _804 + 2;\n            vec4 _1048 = fa_light_texel(param_22);\n            float _1058 = _1048.w;\n            int param_23 = _804 + 3;\n            vec4 _1063 = fa_light_texel(param_23);\n            float _1064 = _1063.x;\n            float cos_inner = _1064;\n            if (_1064 > 1.5)\n            {\n                cos_inner = mix(_1058, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1058, cos_inner, dot(-l, normalize(_1048.xyz)));\n        }\n        if (_808 && (_820 < 1.5))\n        {\n            int param_24 = _804 + 6;\n            vec4 _1088 = fa_light_texel(param_24);\n            if (_1088.z > 0.5)\n            {\n                vec3 _1096 = -to_light;\n                int param_25 = _804 + 4;\n                int param_26 = _804 + 5;\n                vec3 _1110 = fa_light_texel(param_25).xyz;\n                vec3 _1114 = fa_light_texel(param_26).xyz;\n                vec3 _1123 = vec3(dot(_1096, _1110), dot(_1096, _1114), dot(_1096, cross(_1110, _1114)));\n                vec3 param_27 = _1123;\n                int _1127 = fa_cube_face(param_27);\n                int param_28 = _1127;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1154 = vec2(dot(_1123, cross(param_29, param_30)), dot(_1123, param_30)) / vec2(max(dot(_1123, param_29), 9.9999997473787516355514526367188e-05));\n                int _1158 = _1127 / 3;\n                vec2 param_31 = _1088.xy + (vec2(float(_1127 - (_1158 * 3)), float(_1158)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1154.x), 0.5 - (0.5 * _1154.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _804 + 7;\n            vec4 _1188 = fa_light_texel(param_33);\n            if (_1188.z > 0.5)\n            {\n                int param_34 = _804 + 2;\n                int param_35 = _804 + 4;\n                int param_36 = _804 + 5;\n                vec2 param_37 = _1188.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_808 && _1040)\n            {\n                int param_42 = _804 + 6;\n                vec4 _1235 = fa_light_texel(param_42);\n                int param_43 = _804 + 7;\n                vec4 _1240 = fa_light_texel(param_43);\n                bool _1243 = _1235.z > 0.5;\n                bool _1250;\n                if (!_1243)\n                {\n                    _1250 = _1240.z > 0.5;\n                }\n                else\n                {\n                    _1250 = _1243;\n                }\n                if (_1250)\n                {\n                    int param_44 = _804 + 2;\n                    vec4 _1257 = fa_light_texel(param_44);\n                    vec3 _1261 = normalize(_1257.xyz);\n                    int param_45 = _804 + 4;\n                    vec4 _1266 = fa_light_texel(param_45);\n                    int param_46 = _804 + 5;\n                    vec4 _1271 = fa_light_texel(param_46);\n                    if (_1243)\n                    {\n                        vec3 _1279 = -to_light;\n                        float _1286 = _1257.w;\n                        float _1302 = 0.5 / max(dot(_1279, _1261) * (sqrt(max(1.0 - (_1286 * _1286), 0.0)) / max(_1286, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1235.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1279, _1266.xyz) * _1302), 0.5 - (dot(_1279, _1271.xyz) * _1302));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1240.z > 0.5)\n                    {\n                        vec2 param_49 = _1240.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1261;\n                        vec3 param_52 = _1266.xyz;\n                        vec3 param_53 = _1271.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _5629 = _817.xyz * atten;\n    if (_808)\n    {\n        _5629 *= fa_light_tint;\n    }\n    int _1370;\n    if (_834)\n    {\n        _1370 = 0;\n    }\n    else\n    {\n        _1370 = ((_820 > 1.5) && (_820 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _5629, atten, 1.0, dist, _1370);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2153 = fa_shadow_depth(param, param_1);\n    float _2157;\n    if (conv.x < 0.5)\n    {\n        _2157 = _2153;\n    }\n    else\n    {\n        _2157 = (conv.y * conv.z) / (conv.z - (_2153 * (conv.z - conv.y)));\n    }\n    return _2157;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2203 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2209 = vec2(cos(_2203), sin(_2203));\n    vec2 dir = _2209;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2218;\n        if (k < 0.0)\n        {\n            _2218 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2218 = k;\n        }\n        float _2237 = clamp((_2218 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2256 = sqrt((float(i) + 0.5) * 0.0625) * _2237;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2256));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2270 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2270 < (zr - (_2256 * plane)))\n            {\n                sum += _2270;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2298 = sum / cnt;\n        float _2308;\n        if (k < 0.0)\n        {\n            _2308 = (-k) / max(_2298, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2308 = k;\n        }\n        radius = clamp(((max(zr - _2298, 0.0) * unit) * _2308) / texel_m, 1.5, 16.0);\n        dir = _2209;\n    }\n    float lit = 0.0;\n    int _2334 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2334; i_1++)\n    {\n        float _2353 = sqrt((float(i_1) + 0.5) / float(_2334)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2353));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2353 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2334);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2558 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2565;\n    if (!_2558)\n    {\n        _2565 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2565 = _2558;\n    }\n    if (_2565)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2578 = fa_light_texel(param);\n    float _2579 = _2578.x;\n    if (_2579 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2588 = int(_2579 + 0.5);\n    int param_1 = _2588;\n    vec4 _2592 = fa_light_texel(param_1);\n    int param_2 = _2588 + 1;\n    vec4 _2597 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2600 = _2592.y;\n    if (_2600 > 0.0)\n    {\n        float _2617 = 1.0 - smoothstep(0.75 * _2600, _2600, length(world - fa_shadows[27].xyz));\n        fade = _2617;\n        if (_2617 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2592.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2641 = (_2588 + 2) + (face * 6);\n    int param_4 = _2641;\n    int param_5 = _2641 + 1;\n    int param_6 = _2641 + 3;\n    vec4 _2655 = fa_light_texel(param_6);\n    int param_7 = _2641 + 4;\n    vec4 _2660 = fa_light_texel(param_7);\n    int param_8 = _2641 + 5;\n    vec4 _2665 = fa_light_texel(param_8);\n    float _2677 = _2665.x * max(dot(_2655, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2682 = clamp(dot(n, l), 0.0, 1.0);\n    float _2705 = clamp(dot(n, _2655.xyz), -1.0, 1.0);\n    float _2724 = min(sqrt(1.0 - (_2705 * _2705)) / max(abs(dot(n, world - lpos)) / max(dot(_2655, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2727 = _2597.y;\n    float _2729;\n    if (_2727 > 0.0)\n    {\n        _2729 = _2727;\n    }\n    else\n    {\n        _2729 = 1.5 * _2677;\n    }\n    vec4 _2749 = vec4(world + (n * (_2729 * sqrt(1.0 - (_2682 * _2682)))), 1.0);\n    float _2753 = dot(_2655, _2749);\n    float _2756 = _2665.y;\n    if (_2753 < _2756)\n    {\n        return 1.0;\n    }\n    vec2 _2771 = vec2(dot(fa_light_texel(param_4), _2749), dot(fa_light_texel(param_5), _2749)) / vec2(_2753);\n    float _2773 = _2771.x;\n    bool _2776 = _2773 < _2660.x;\n    bool _2785;\n    if (!_2776)\n    {\n        _2785 = _2773 > _2660.z;\n    }\n    else\n    {\n        _2785 = _2776;\n    }\n    bool _2794;\n    if (!_2785)\n    {\n        _2794 = _2771.y < _2660.y;\n    }\n    else\n    {\n        _2794 = _2785;\n    }\n    bool _2803;\n    if (!_2794)\n    {\n        _2803 = _2771.y > _2660.w;\n    }\n    else\n    {\n        _2803 = _2794;\n    }\n    if (_2803)\n    {\n        return 1.0;\n    }\n    float _2809 = _2597.x;\n    float _2811;\n    if (_2809 > 0.0)\n    {\n        _2811 = _2809;\n    }\n    else\n    {\n        _2811 = 1.5 * _2677;\n    }\n    vec2 param_9 = _2771;\n    vec4 param_10 = _2660;\n    float param_11 = _2753 - (_2811 * (1.0 + (0.5 * _2724)));\n    float param_12 = _2677;\n    float param_13 = 1.0;\n    float param_14 = _2665.z * 0.25;\n    float param_15 = (_2677 * min(_2724, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2756, _2665.z);\n    int param_17 = int(_2592.z + 0.5);\n    float param_18 = _2592.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2096;\n    if (i == 0)\n    {\n        _2096 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2112;\n        if (i == 1)\n        {\n            _2112 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2120;\n            if (i == 2)\n            {\n                _2120 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2120 = fa_shadows[24].w;\n            }\n            _2112 = _2120;\n        }\n        _2096 = _2112;\n    }\n    return _2096;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2399 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2404 = clamp(dot(n, l), 0.0, 1.0);\n    float _2410 = sqrt(1.0 - (_2404 * _2404));\n    float _2418 = min(_2410 / max(_2404, 0.20000000298023223876953125), 4.0);\n    float _2423;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2423 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2423 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2448 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2423 * _2410)), 1.0);\n    float _2455 = _2448.x;\n    bool _2458 = _2455 < fa_shadows[ci * 1 + 16].x;\n    bool _2467;\n    if (!_2458)\n    {\n        _2467 = _2455 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2467 = _2458;\n    }\n    bool _2476;\n    if (!_2467)\n    {\n        _2476 = _2448.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2476 = _2467;\n    }\n    bool _2485;\n    if (!_2476)\n    {\n        _2485 = _2448.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2485 = _2476;\n    }\n    bool _2492;\n    if (!_2485)\n    {\n        _2492 = _2448.z > 1.0;\n    }\n    else\n    {\n        _2492 = _2485;\n    }\n    if (_2492)\n    {\n        return -1.0;\n    }\n    float _2500;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2500 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2500 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2448.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2448.z - ((_2500 * (1.0 + (0.5 * _2418))) / _2399);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2399;\n    float param_5 = _2399 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2418, 3.0)) * 0.5) / _2399;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2878 = int(fa_shadows[25].x + 0.5);\n    if (_2878 < 1)\n    {\n        return 1.0;\n    }\n    float _2893 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2878 - 1;\n    if (_2893 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2905 = _2878 > 1;\n    bool _2912;\n    if (_2905)\n    {\n        _2912 = _2893 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2912 = _2905;\n    }\n    if (_2912)\n    {\n        ci = 1;\n    }\n    bool _2916 = _2878 > 2;\n    bool _2923;\n    if (_2916)\n    {\n        _2923 = _2893 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2923 = _2916;\n    }\n    if (_2923)\n    {\n        ci = 2;\n    }\n    bool _2927 = _2878 > 3;\n    bool _2934;\n    if (_2927)\n    {\n        _2934 = _2893 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2934 = _2927;\n    }\n    if (_2934)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2945 = min(_2878, 4);\n    float _2986;\n    for (int c = ci; c < _2945; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2965 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2965;\n            break;\n        }\n        if (_2965 < 0.0)\n        {\n            continue;\n        }\n        s = _2965;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2986 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2986 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3005 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2986, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2893 - (fa_shadow_split_at(param_7) - _3005)) / _3005, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3037;\n        if ((ci + 1) < _2878)\n        {\n            _3037 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3037 = 1.0;\n        }\n        s = mix(s, _3037, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3492 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3499;\n    if (!_3492)\n    {\n        _3499 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3499 = _3492;\n    }\n    if (_3499)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3512 = fa_light_texel(param);\n    float _3513 = _3512.y;\n    float len = _3513;\n    if (_3513 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3525 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3535 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3525);\n    if (_3535 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3541 = len;\n    float _3544 = min(_3541, 0.89999997615814208984375 * dist);\n    len = _3544;\n    float _3550 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3525);\n    float _3555 = _3550 + (0.5 * _3544);\n    vec3 _3561 = world + (gn * _3550);\n    float _3563 = fa_shadow_noise();\n    float occ = 0.0;\n    float _3628;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3579 = (float(k) + _3563) * 0.083333335816860198974609375;\n        vec3 _3587 = _3561 + (l * (_3579 * len));\n        vec4 _3593 = vec4(_3587, 1.0);\n        float _3599 = dot(fa_mesh_fs_params[28], _3593);\n        if (_3599 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _3619 = vec2(dot(fa_mesh_fs_params[26], _3593), dot(fa_mesh_fs_params[27], _3593)) / vec2(_3599);\n        float _3623 = _3619.x * 0.5;\n        float _3624 = _3623 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _3628 = (_3619.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3628 = 0.5 - (_3619.y * 0.5);\n        }\n        bool _3644 = _3624 < 0.0;\n        bool _3651;\n        if (!_3644)\n        {\n            _3651 = _3624 >= 1.0;\n        }\n        else\n        {\n            _3651 = _3644;\n        }\n        bool _3658;\n        if (!_3651)\n        {\n            _3658 = _3628 < 0.0;\n        }\n        else\n        {\n            _3658 = _3651;\n        }\n        bool _3665;\n        if (!_3658)\n        {\n            _3665 = _3628 >= 1.0;\n        }\n        else\n        {\n            _3665 = _3658;\n        }\n        if (_3665)\n        {\n            break;\n        }\n        vec4 _3692 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3624, _3628) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_3692.w < 0.5)\n        {\n            continue;\n        }\n        float _3711 = (dot(fa_mesh_fs_params[29].xyz, _3587) + fa_mesh_fs_params[29].w) - _3692.x;\n        if ((_3711 > _3550) && (_3711 < _3555))\n        {\n            occ = max(occ, (1.0 - (_3579 * _3579)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_3624, 0.5 - _3623), min(_3628, 1.0 - _3628))));\n        }\n    }\n    return 1.0 - (occ * _3535);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _3814 = fa_baked_keep(param);\n    if (_3814 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3840 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _5655 = _3840.color;\n    float _5656 = _3840.attenuation;\n    float _5657 = _3840.shadow;\n    bool _3843 = _3840.type == 0;\n    if (_3843 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3840.direction;\n        float _3854 = fa_shadow_factor(param_5, param_6);\n        _5657 = _3854;\n        _5655 *= _3854;\n    }\n    else\n    {\n        bool _3865 = _3840.type != 0;\n        bool _3871;\n        if (_3865)\n        {\n            _3871 = _5656 > 0.0;\n        }\n        else\n        {\n            _3871 = _3865;\n        }\n        if (_3871)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _3840.direction;\n            float _3890 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5657 = _3890;\n            _5655 *= _3890;\n        }\n    }\n    bool _3900 = fa_mesh_fs_params[24].x > 0.5;\n    bool _3906;\n    if (_3900)\n    {\n        _3906 = _5656 > 0.0;\n    }\n    else\n    {\n        _3906 = _3900;\n    }\n    if (_3906)\n    {\n        float _3913;\n        if (_3843)\n        {\n            _3913 = 1000000000.0;\n        }\n        else\n        {\n            _3913 = _3840._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _3840.direction;\n        float param_18 = _3913;\n        float _3931 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5657 *= _3931;\n        _5655 *= _3931;\n    }\n    float _3944 = _5656;\n    float _3945 = _3944 * _3814;\n    _5656 = _3945;\n    vec3 _3949 = _5655;\n    vec3 _3950 = _3949 * _3814;\n    _5655 = _3950;\n    return LightSample(_3840.direction, _3950, _3945, _5657, _3840._distance, _3840.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3065 = int(fa_shadows[25].x + 0.5);\n    float _3075 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3080 = _3065 > 0;\n    bool _3089;\n    if (_3080)\n    {\n        int param = _3065 - 1;\n        _3089 = _3075 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3089 = _3080;\n    }\n    if (_3089)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3095 = _3065 > 1;\n        bool _3102;\n        if (_3095)\n        {\n            _3102 = _3075 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3102 = _3095;\n        }\n        if (_3102)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3108 = _3065 > 2;\n        bool _3115;\n        if (_3108)\n        {\n            _3115 = _3075 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3115 = _3108;\n        }\n        if (_3115)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3121 = _3065 > 3;\n        bool _3128;\n        if (_3121)\n        {\n            _3128 = _3075 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3128 = _3121;\n        }\n        if (_3128)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5447 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5447 = -_5447;\n    }\n    vec3 _5020 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5447, fa_world_tangent, fa_uv, fa_vertex_color, _5020, gl_FrontFacing);\n    Surface _5028 = fa_standard_surface(param_1);\n    vec3 _5486 = _5028.albedo;\n    float _5487 = _5028.alpha;\n    vec3 _5488 = _5028.normal;\n    float _5489 = _5028.metallic;\n    float _5490 = _5028.roughness;\n    float _5491 = _5028.occlusion;\n    vec3 _5492 = _5028.emission;\n    float _5493 = _5028.clearcoat;\n    float _5494 = _5028.clearcoat_roughness;\n    vec3 _5495 = _5028.sheen_color;\n    float _5496 = _5028.sheen_roughness;\n    float _5497 = _5028.anisotropy;\n    float _5498 = _5028.anisotropy_rotation;\n    float _5499 = _5028.specular;\n    float _5500 = _5028.ior;\n    vec3 _5501 = _5028.specular_color;\n    float _5502 = _5028.transmission;\n    float _5503 = _5028.thickness;\n    vec3 _5504 = _5028.attenuation_color;\n    float _5505 = _5028.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5447, fa_world_tangent, fa_uv, fa_vertex_color, _5020, gl_FrontFacing);\n    Surface param_3 = _5028;\n    surface(param_2, param_3);\n    _5486 = param_3.albedo;\n    _5487 = param_3.alpha;\n    _5488 = param_3.normal;\n    _5489 = param_3.metallic;\n    _5490 = param_3.roughness;\n    _5491 = param_3.occlusion;\n    _5492 = param_3.emission;\n    _5493 = param_3.clearcoat;\n    _5494 = param_3.clearcoat_roughness;\n    _5495 = param_3.sheen_color;\n    _5496 = param_3.sheen_roughness;\n    _5497 = param_3.anisotropy;\n    _5498 = param_3.anisotropy_rotation;\n    _5499 = param_3.specular;\n    _5500 = param_3.ior;\n    _5501 = param_3.specular_color;\n    _5502 = param_3.transmission;\n    _5503 = param_3.thickness;\n    _5504 = param_3.attenuation_color;\n    _5505 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5447;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5486 = param_6;\n    _5488 = param_7;\n    fa_lod_dither();\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5486;\n    }\n    else\n    {\n        vec3 _5068 = _5488;\n        vec3 _5069 = normalize(_5068);\n        _5488 = _5069;\n        vec3 param_8 = _5069;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _5447, fa_world_tangent, fa_uv, fa_vertex_color, _5020, gl_FrontFacing);\n        Surface param_10 = Surface(_5486, _5487, _5488, _5489, _5490, _5491, _5492, _5493, _5494, _5495, _5496, _5497, _5498, _5499, _5500, _5501, _5502, _5503, _5504, _5505);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _5088 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5088; ln++)\n        {\n            int param_12 = ln;\n            int _5101 = fa_cl_light(param_12);\n            int param_13 = _5101;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _5101;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _5447;\n            LightSample _5117 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _5447, fa_world_tangent, fa_uv, fa_vertex_color, _5020, gl_FrontFacing);\n            Surface param_18 = Surface(_5486, _5487, _5488, _5489, _5490, _5491, _5492, _5493, _5494, _5495, _5496, _5497, _5498, _5499, _5500, _5501, _5502, _5503, _5504, _5505);\n            LightSample param_19 = _5117;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _5132 = result;\n    vec3 _5133 = _5132 + _5492;\n    result = _5133;\n    vec3 param_20 = _5133;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _5142 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5149;\n    if (!_5142)\n    {\n        _5149 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5149 = _5142;\n    }\n    if (_5149)\n    {\n        vec3 _5158 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5164 = dot(_5158, fa_mesh_fs_params[9].xyz);\n        bool _5168 = fa_mesh_fs_params[9].w > 0.5;\n        float _5169;\n        if (_5168)\n        {\n            _5169 = _5164;\n        }\n        else\n        {\n            _5169 = length(_5158);\n        }\n        float _5181 = _5169 - fa_mesh_fs_params[8].x;\n        if (_5181 > 0.0)\n        {\n            float _5190 = fa_mesh_fs_params[7].w * _5181;\n            float tau = _5190 * _5190;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5206;\n                if (_5168)\n                {\n                    _5206 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5164);\n                }\n                else\n                {\n                    _5206 = fa_mesh_fs_params[0].y;\n                }\n                float _5227 = mix(_5206, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5169, 0.0, 1.0));\n                float _5231 = fa_world_pos.y - _5227;\n                float _5236 = _5227 - fa_mesh_fs_params[8].z;\n                float _5241 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5244 = _5236 <= 0.0;\n                bool _5245 = !_5244;\n                bool _5251;\n                if (_5245)\n                {\n                    _5251 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5251 = _5244;\n                }\n                float _5252;\n                if (_5251)\n                {\n                    _5252 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5252 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5236, 80.0));\n                }\n                bool _5279;\n                if (_5245)\n                {\n                    _5279 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5279 = _5244;\n                }\n                float _5280;\n                if (_5279)\n                {\n                    _5280 = fa_mesh_fs_params[8].y * _5236;\n                }\n                else\n                {\n                    _5280 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5236, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5305 = _5241 <= 0.0;\n                bool _5312;\n                if (!_5305)\n                {\n                    _5312 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5312 = _5305;\n                }\n                float _5313;\n                if (_5312)\n                {\n                    _5313 = fa_mesh_fs_params[8].y * _5241;\n                }\n                else\n                {\n                    _5313 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5241, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5340;\n                if (abs(_5231) < 0.001000000047497451305389404296875)\n                {\n                    _5340 = _5252;\n                }\n                else\n                {\n                    _5340 = (_5313 - _5280) / _5231;\n                }\n                tau += (_5181 * max(_5340, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5487);\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_372",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
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
            "inst_name": "_2106",
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
              "name": "fa_probe_atlas",
              "multisampled": false,
              "type": "2d",
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
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1388 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1395;\n    if (!_1388)\n    {\n        _1395 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1395 = _1388;\n    }\n    bool _1403;\n    if (!_1395)\n    {\n        _1403 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1403 = _1395;\n    }\n    bool _1410;\n    if (!_1403)\n    {\n        _1410 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1410 = _1403;\n    }\n    bool _1417;\n    if (!_1410)\n    {\n        _1417 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1417 = _1410;\n    }\n    if (_1417)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1427 = vec4(world_pos, 1.0);\n    float _1433 = dot(fa_mesh_fs_params[16], _1427);\n    if (!(_1433 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1455 = vec2(dot(fa_mesh_fs_params[14], _1427), dot(fa_mesh_fs_params[15], _1427)) / vec2(_1433);\n    int _1459 = int(fa_mesh_fs_params[18].x);\n    int _1463 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1463) + clamp(int(floor(((_1455.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1463 - 1)) * _1459)) + clamp(int(floor(((_1455.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1459 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1539 = fa_cluster_texel(param);\n    return ivec2(int(_1539.x), int(_1539.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3788 = fa_cluster_lookup(param);\n    fa_cl_slot = _3788.x;\n    fa_cl_local = _3788.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3998 = fa_linear_to_srgb(param);\n        c = _3998;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4006 = fa_srgb_to_linear(param_1);\n            c = _4006;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _304;\n    if (i.front_facing)\n    {\n        _304 = i.world_normal;\n    }\n    else\n    {\n        _304 = -i.world_normal;\n    }\n    vec3 _328 = normalize(i.world_tangent.xyz - (_304 * dot(_304, i.world_tangent.xyz)));\n    vec3 _355 = normalize(((_328 * m.x) + ((cross(_304, _328) * i.world_tangent.w) * m.y)) + (_304 * m.z));\n    vec3 _358;\n    if (i.front_facing)\n    {\n        _358 = _355;\n    }\n    else\n    {\n        _358 = -_355;\n    }\n    return _358;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4037 = fa_tex_fix(param_2, param_3);\n    vec4 _5838 = base_t;\n    _5838.x = _4037.x;\n    _5838.y = _4037.y;\n    _5838.z = _4037.z;\n    base_t = _5838;\n    vec4 _4051 = (_5838 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _5675 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4083 = fa_tex_fix(param_6, param_7);\n        vec3 _4086 = (_4083 * 2.0) - vec3(1.0);\n        vec2 _4091 = _4086.xy * fa_mesh_fs_params[6].x;\n        vec3 _5846 = _4086;\n        _5846.x = _4091.x;\n        _5846.y = _4091.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5846;\n        _5675 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4119 = fa_tex_fix(param_12, param_13);\n    vec4 _5849 = mrt;\n    _5849.x = _4119.x;\n    _5849.y = _4119.y;\n    _5849.z = _4119.z;\n    mrt = _5849;\n    vec4 _4147 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4147.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4158 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4188 = fa_tex_fix(param_20, param_21);\n    float _5680 = fa_mesh_fs_params[20].x;\n    float _5681 = fa_mesh_fs_params[20].y;\n    float _5684 = fa_mesh_fs_params[20].z;\n    float _5683 = fa_mesh_fs_params[21].w;\n    float _5686 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _5680 *= _4158.y;\n            _5681 *= _4158.z;\n            _5683 *= _4147.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _5684 *= mrt.x;\n            _5686 *= mrt.w;\n        }\n    }\n    return Surface(_4051.xyz, _4051.w, _5675, clamp(fa_mesh_fs_params[5].x * _4119.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4119.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4158.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4188), _5680, _5681, fa_mesh_fs_params[21].xyz, _5683, _5684, fa_mesh_fs_params[20].w, _5686, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1619 = rect.zw - rect.xy;\n    vec2 _1623 = _1619 * atlas;\n    vec2 _1627 = ddx * _1623;\n    vec2 _1631 = ddy * _1623;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1619), clamp(0.5 * log2(max(max(dot(_1627, _1627), dot(_1631, _1631)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1664 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1671;\n    if (!_1664)\n    {\n        _1671 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1671 = _1664;\n    }\n    if (_1671)\n    {\n        return;\n    }\n    vec3 _1677 = dFdx(world_pos);\n    vec3 _1680 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1684 = fa_cluster_texel(param);\n    int _1688 = int(_1684.w);\n    if (_1688 < 1)\n    {\n        return;\n    }\n    int _1698 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1698;\n    vec4 _1702 = fa_light_texel(param_1);\n    vec2 _1705 = _1702.yz;\n    int _1709 = int(_1702.w);\n    int param_2 = _1698 + 1;\n    vec4 _1714 = fa_light_texel(param_2);\n    float _1715 = _1714.x;\n    int _1721 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1725 = int(_1684.z);\n    vec3 _1990;\n    for (int k = 0; k < _1688; k++)\n    {\n        int _1738 = _1725 + k;\n        int param_3 = _1709 + (_1738 >> 2);\n        int _1755 = (_1698 + 2) + (int(fa_light_texel(param_3)[_1738 & 3]) * 7);\n        int param_4 = _1755 + 6;\n        vec4 _1760 = fa_light_texel(param_4);\n        if (((int(_1760.w + 0.5) >> _1721) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1755;\n        vec4 _1775 = fa_light_texel(param_5);\n        int param_6 = _1755 + 1;\n        vec4 _1780 = fa_light_texel(param_6);\n        int param_7 = _1755 + 2;\n        vec4 _1785 = fa_light_texel(param_7);\n        vec3 _1788 = _1775.xyz;\n        float _1793 = dot(_1788, world_pos) + _1775.w;\n        vec3 _1795 = _1780.xyz;\n        float _1800 = dot(_1795, world_pos) + _1780.w;\n        vec3 _1802 = _1785.xyz;\n        float _1807 = dot(_1802, world_pos) + _1785.w;\n        bool _1812 = abs(_1793) > 0.5;\n        bool _1820;\n        if (!_1812)\n        {\n            _1820 = abs(_1800) > 0.5;\n        }\n        else\n        {\n            _1820 = _1812;\n        }\n        bool _1828;\n        if (!_1820)\n        {\n            _1828 = abs(_1807) > 0.5;\n        }\n        else\n        {\n            _1828 = _1820;\n        }\n        if (_1828)\n        {\n            continue;\n        }\n        float _1843 = clamp(dot(geo_normal, normalize(_1802)) * _1760.z, 0.0, 1.0);\n        if (_1843 <= 0.0)\n        {\n            continue;\n        }\n        float _1863 = (clamp((0.5 - abs(_1807)) * 10.0, 0.0, 1.0) * _1843) * _1760.x;\n        vec2 _1871 = vec2(_1793 + 0.5, 0.5 - _1800);\n        vec2 _1881 = vec2(dot(_1788, _1677), dot(_1795, _1677));\n        vec2 _1891 = vec2(dot(_1788, _1680), dot(_1795, _1680));\n        int param_8 = _1755 + 5;\n        vec4 _1896 = fa_light_texel(param_8);\n        int param_9 = _1755 + 3;\n        vec4 _1901 = fa_light_texel(param_9);\n        int param_10 = _1755 + 4;\n        vec4 _1906 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1896.xyz;\n        bool _1916 = _1901.z > _1901.x;\n        if (_1916)\n        {\n            vec4 param_11 = _1901;\n            vec2 param_12 = _1871;\n            vec2 param_13 = _1705;\n            vec2 param_14 = _1881;\n            vec2 param_15 = _1891;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1715 > 0.5) && (_1715 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1942 = fa_dc_to_linear(param_16);\n                vec4 _5763 = tx;\n                _5763.x = _1942.x;\n                _5763.y = _1942.y;\n                _5763.z = _1942.z;\n                tx = _5763;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1863 * tex_a) * _1896.w, 0.0, 1.0)));\n        if (_1906.z > _1906.x)\n        {\n            vec4 param_17 = _1906;\n            vec2 param_18 = _1871;\n            vec2 param_19 = _1705;\n            vec2 param_20 = _1881;\n            vec2 param_21 = _1891;\n            vec4 _1986 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1715 > 1.5)\n            {\n                vec3 param_22 = _1986.xyz;\n                vec3 _1996 = fa_dc_to_srgb(param_22);\n                _1990 = _1996;\n            }\n            else\n            {\n                _1990 = _1986.xyz;\n            }\n            vec3 _2005 = (_1990 * 2.0) - vec3(1.0);\n            vec2 _2010 = _2005.xy * _1760.y;\n            vec3 _2032 = (normalize(_1788) * _2010.x) + (normalize(_1795) * _2010.y);\n            vec3 _2035 = normalize(normal);\n            normal = normalize(mix(_2035, normalize((_2035 * max(_2005.z, 0.0500000007450580596923828125)) + (_2032 - (_2035 * dot(_2035, _2032)))), vec3(clamp(_1863 * (_1916 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _394 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _397;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _397 = _394 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _397 = _394 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_397)\n        {\n            discard;\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3242 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3242;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3352 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3358 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3352 > 0.0005000000237487256526947021484375)\n    {\n        if (_3358)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3352;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3352;\n        }\n    }\n    bool _3410 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3410)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _3441 = fa_mesh_fs_params[47].w > 0.0;\n    if (_3441)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3358 || _3410) || _3441)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3262 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3265 = _3262.x;\n    float _3267 = _3262.z;\n    vec2 e = vec2(_3265, _3267);\n    if (_3262.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3267)) * ((_3265 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3265)) * ((_3267 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _4302 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _4307 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _4312 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _4317 = fa_light_texel(param_3);\n    bool _4320 = _4317.z < 0.5;\n    bool _4328;\n    if (!_4320)\n    {\n        _4328 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _4328 = _4320;\n    }\n    if (_4328)\n    {\n        return vec3(0.0);\n    }\n    float _4335 = max(_4302.w, 9.9999997473787516355514526367188e-05);\n    vec3 _4338 = _4307.xyz;\n    vec3 _4342 = _4302.xyz;\n    vec3 _4346 = (fa_world_pos - _4342) / vec3(_4335);\n    vec3 _4355 = min(_4346 + vec3(0.5), (_4338 - vec3(0.5)) - _4346);\n    float _4364 = min(_4355.x, min(_4355.y, _4355.z));\n    if (!(_4364 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4379 = _4338 - vec3(1.0);\n    vec3 _4380 = clamp(_4346, vec3(0.0), _4379);\n    vec3 _4388 = min(floor(_4380), max(_4338 - vec3(2.0), vec3(0.0)));\n    vec3 _4392 = _4380 - _4388;\n    vec3 _4404 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _4335));\n    int _4409 = int(_4312.y + 0.5);\n    float _4414 = 0.3257350027561187744140625 * n.y;\n    float _4418 = 0.3257350027561187744140625 * n.z;\n    float _4422 = 0.3257350027561187744140625 * n.x;\n    float _4429 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _4436 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _4445 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _4452 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _4465 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _4472 = 8 + int(_4317.w);\n    float _4499;\n    float _4512;\n    float _4526;\n    for (int k = 0; k < _4472; k++)\n    {\n        float _4485 = float(k & 1);\n        float _4489 = float((k >> 1) & 1);\n        float _4493 = float((k >> 2) & 1);\n        if (_4485 > 0.5)\n        {\n            _4499 = _4392.x;\n        }\n        else\n        {\n            _4499 = 1.0 - _4392.x;\n        }\n        if (_4489 > 0.5)\n        {\n            _4512 = _4392.y;\n        }\n        else\n        {\n            _4512 = 1.0 - _4392.y;\n        }\n        if (_4493 > 0.5)\n        {\n            _4526 = _4392.z;\n        }\n        else\n        {\n            _4526 = 1.0 - _4392.z;\n        }\n        float _4536 = (_4499 * _4512) * _4526;\n        if (!(_4536 > 0.0))\n        {\n            continue;\n        }\n        vec3 _4549 = min(_4388 + vec3(_4485, _4489, _4493), _4379);\n        int _4569 = int(((_4312.x + _4549.x) + (_4307.x * (_4549.y + (_4307.y * _4549.z)))) + 0.5);\n        vec2 _4584 = vec2(float(_4569 % _4409) * 10.0, 1024.0 + (float(_4569 / _4409) * 11.0));\n        vec2 param_4 = _4584 + vec2(9.5, 10.5);\n        vec4 _4592 = fa_gi_fetch(param_4);\n        bool _4595 = _4592.y < 0.5;\n        bool _4604;\n        if (!_4595)\n        {\n            _4604 = _4592.x > _4317.y;\n        }\n        else\n        {\n            _4604 = _4595;\n        }\n        if (_4604)\n        {\n            continue;\n        }\n        vec3 _4616 = _4404 - (_4342 + (_4549 * _4335));\n        float _4619 = length(_4616);\n        vec3 _4625 = _4616 / vec3(max(_4619, 9.9999997473787516355514526367188e-05));\n        float _4635 = max(9.9999997473787516355514526367188e-05, (dot(-_4625, n) + 1.0) * 0.5);\n        float w = _4536 * (_4635 * _4635);\n        vec3 param_5 = _4625;\n        vec2 param_6 = (_4584 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _4655 = fa_gi_fetch(param_6);\n        float _4662 = _4619 / max(_4312.z, 9.9999997473787516355514526367188e-05);\n        float _4665 = _4655.x;\n        if (_4662 > _4665)\n        {\n            float _4678 = max(_4655.y - (_4665 * _4665), 0.0);\n            float _4683 = _4662 - _4665;\n            float _4692 = _4678 / max(_4678 + (_4683 * _4683), 9.9999999600419720025001879548654e-13);\n            w *= ((_4692 * _4692) * _4692);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _4584 + vec2(0.5, 10.5);\n        vec2 param_8 = _4584 + vec2(1.5, 10.5);\n        vec2 param_9 = _4584 + vec2(2.5, 10.5);\n        vec2 param_10 = _4584 + vec2(3.5, 10.5);\n        vec2 param_11 = _4584 + vec2(4.5, 10.5);\n        vec2 param_12 = _4584 + vec2(5.5, 10.5);\n        vec2 param_13 = _4584 + vec2(6.5, 10.5);\n        vec2 param_14 = _4584 + vec2(7.5, 10.5);\n        vec2 param_15 = _4584 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _4414)) + (fa_gi_fetch(param_9).xyz * _4418)) + (fa_gi_fetch(param_10).xyz * _4422)) + (fa_gi_fetch(param_11).xyz * _4429)) + (fa_gi_fetch(param_12).xyz * _4436)) + (fa_gi_fetch(param_13).xyz * _4445)) + (fa_gi_fetch(param_14).xyz * _4452)) + (fa_gi_fetch(param_15).xyz * _4465)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_4364 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _4819;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _4819 = _4317.x;\n    }\n    else\n    {\n        _4819 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_4312.w * _4819);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _4843 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _4848 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _4853 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _4853) && (k < 8); k++)\n    {\n        int param = _4848 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _4843;\n        vec3 _4878 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _4883 = param_3 * left;\n        acc += (_4878 * _4883);\n        left -= _4883;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _4912 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _4912;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return vec3(0.0, ambientColor.y, 0.0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3758;\n    if (fa_lm.z > 0.5)\n    {\n        _3758 = 0.0;\n    }\n    else\n    {\n        _3758 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _3769 = _3758 < 1.0;\n    bool _3775;\n    if (_3769)\n    {\n        int param = li;\n        _3775 = fa_light_baked(param);\n    }\n    else\n    {\n        _3775 = _3769;\n    }\n    return _3775 ? _3758 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _638 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _651 = (c - (ru * hx)) - p;\n        vec3 _657 = ru * (2.0 * hx);\n        float _663 = max(dot(_657, _657), 9.9999999392252902907785028219223e-09);\n        float _667 = dot(_651, _657);\n        float t = clamp((-_667) / _663, 0.0, 1.0);\n        if (_638)\n        {\n            float _682 = dot(r, _657);\n            float _688 = _663 - (_682 * _682);\n            if (abs(_688) > (9.9999997473787516355514526367188e-06 * _663))\n            {\n                t = clamp(((dot(r, _651) * _682) - _667) / _688, 0.0, 1.0);\n            }\n        }\n        return (p + _651) + (_657 * t);\n    }\n    vec3 q = p;\n    float _720 = dot(r, axis);\n    bool _728;\n    if (_638)\n    {\n        _728 = abs(_720) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _728 = _638;\n    }\n    if (_728)\n    {\n        float _738 = dot(c - p, axis) / _720;\n        if (_738 > 0.0)\n        {\n            q = p + (r * _738);\n        }\n    }\n    vec3 _751 = q - c;\n    vec2 xy = vec2(dot(_751, ru), dot(_751, uu));\n    if (shape > 0.5)\n    {\n        float _766 = length(xy);\n        if (_766 > hx)\n        {\n            xy *= (hx / _766);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _558 = dot(d, right);\n    float _562 = dot(d, up);\n    float _573;\n    if (((_558 * _558) + (_562 * _562)) > 1.0000000133514319600180897396058e-10)\n    {\n        _573 = atan(_562, _558) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _573 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_573 - floor(_573)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _414 = abs(d);\n    float _416 = _414.x;\n    float _418 = _414.y;\n    bool _419 = _416 >= _418;\n    bool _427;\n    if (_419)\n    {\n        _427 = _416 >= _414.z;\n    }\n    else\n    {\n        _427 = _419;\n    }\n    int _428;\n    if (_427)\n    {\n        _428 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _442;\n        if (_418 >= _414.z)\n        {\n            _442 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _442 = (d.z > 0.0) ? 4 : 5;\n        }\n        _428 = _442;\n    }\n    return _428;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _804 = fa_light_base(param);\n    bool _808 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _804;\n    vec4 _812 = fa_light_texel(param_1);\n    int param_2 = _804 + 1;\n    vec4 _817 = fa_light_texel(param_2);\n    float _820 = _817.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _832 = _808 && (_820 > 2.5);\n    fa_light_is_area = _832;\n    bool _834 = _820 < 0.5;\n    vec3 l;\n    if (_834)\n    {\n        l = normalize(_812.xyz);\n        if (_808)\n        {\n            int param_3 = _804 + 6;\n            vec4 _848 = fa_light_texel(param_3);\n            if (_848.z > 0.5)\n            {\n                int param_4 = _804 + 4;\n                vec4 _858 = fa_light_texel(param_4);\n                int param_5 = _804 + 5;\n                vec4 _863 = fa_light_texel(param_5);\n                vec2 param_6 = _848.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _858.xyz) * _858.w, (-dot(world_pos, _863.xyz)) * _863.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _893 = _812.xyz;\n        vec3 _895 = _893 - world_pos;\n        vec3 to_light = _895;\n        float _898 = length(_895);\n        float reach = _898;\n        bool front = true;\n        if (_832)\n        {\n            int param_8 = _804 + 7;\n            reach = max(_898 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _804 + 4;\n            vec4 _922 = fa_light_texel(param_9);\n            int param_10 = _804 + 5;\n            vec4 _927 = fa_light_texel(param_10);\n            int param_11 = _804 + 6;\n            vec4 _932 = fa_light_texel(param_11);\n            float _933 = _932.w;\n            int param_12 = _804 + 2;\n            vec3 _940 = normalize(fa_light_texel(param_12).xyz);\n            bool _942 = _933 > 1.5;\n            bool _950;\n            if (!_942)\n            {\n                _950 = dot(_940, to_light) < 0.0;\n            }\n            else\n            {\n                _950 = _942;\n            }\n            front = _950;\n            vec3 r = vec3(0.0);\n            vec3 _959 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _963 = dot(n, n) > 0.5;\n            bool _971;\n            if (_963)\n            {\n                _971 = dot(_959, _959) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _971 = _963;\n            }\n            if (_971)\n            {\n                r = reflect(-normalize(_959), normalize(n));\n            }\n            vec3 param_13 = _893;\n            vec3 param_14 = _940;\n            vec3 param_15 = _922.xyz;\n            vec3 param_16 = _927.xyz;\n            float param_17 = _922.w;\n            float param_18 = _927.w;\n            float param_19 = _933;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1007 = length(to_light);\n        dist = _1007;\n        l = to_light / vec3(max(_1007, 9.9999997473787516355514526367188e-05));\n        float _1021 = reach / max(_812.w, 0.001000000047497451305389404296875);\n        float _1027 = clamp(1.0 - (_1021 * _1021), 0.0, 1.0);\n        float _1029;\n        if (front)\n        {\n            _1029 = _1027 * _1027;\n        }\n        else\n        {\n            _1029 = 0.0;\n        }\n        atten = _1029;\n        bool _1040 = _820 < 2.5;\n        if ((_820 > 1.5) && _1040)\n        {\n            int param_22 = _804 + 2;\n            vec4 _1048 = fa_light_texel(param_22);\n            float _1058 = _1048.w;\n            int param_23 = _804 + 3;\n            vec4 _1063 = fa_light_texel(param_23);\n            float _1064 = _1063.x;\n            float cos_inner = _1064;\n            if (_1064 > 1.5)\n            {\n                cos_inner = mix(_1058, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1058, cos_inner, dot(-l, normalize(_1048.xyz)));\n        }\n        if (_808 && (_820 < 1.5))\n        {\n            int param_24 = _804 + 6;\n            vec4 _1088 = fa_light_texel(param_24);\n            if (_1088.z > 0.5)\n            {\n                vec3 _1096 = -to_light;\n                int param_25 = _804 + 4;\n                int param_26 = _804 + 5;\n                vec3 _1110 = fa_light_texel(param_25).xyz;\n                vec3 _1114 = fa_light_texel(param_26).xyz;\n                vec3 _1123 = vec3(dot(_1096, _1110), dot(_1096, _1114), dot(_1096, cross(_1110, _1114)));\n                vec3 param_27 = _1123;\n                int _1127 = fa_cube_face(param_27);\n                int param_28 = _1127;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1154 = vec2(dot(_1123, cross(param_29, param_30)), dot(_1123, param_30)) / vec2(max(dot(_1123, param_29), 9.9999997473787516355514526367188e-05));\n                int _1158 = _1127 / 3;\n                vec2 param_31 = _1088.xy + (vec2(float(_1127 - (_1158 * 3)), float(_1158)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1154.x), 0.5 - (0.5 * _1154.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _804 + 7;\n            vec4 _1188 = fa_light_texel(param_33);\n            if (_1188.z > 0.5)\n            {\n                int param_34 = _804 + 2;\n                int param_35 = _804 + 4;\n                int param_36 = _804 + 5;\n                vec2 param_37 = _1188.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_808 && _1040)\n            {\n                int param_42 = _804 + 6;\n                vec4 _1235 = fa_light_texel(param_42);\n                int param_43 = _804 + 7;\n                vec4 _1240 = fa_light_texel(param_43);\n                bool _1243 = _1235.z > 0.5;\n                bool _1250;\n                if (!_1243)\n                {\n                    _1250 = _1240.z > 0.5;\n                }\n                else\n                {\n                    _1250 = _1243;\n                }\n                if (_1250)\n                {\n                    int param_44 = _804 + 2;\n                    vec4 _1257 = fa_light_texel(param_44);\n                    vec3 _1261 = normalize(_1257.xyz);\n                    int param_45 = _804 + 4;\n                    vec4 _1266 = fa_light_texel(param_45);\n                    int param_46 = _804 + 5;\n                    vec4 _1271 = fa_light_texel(param_46);\n                    if (_1243)\n                    {\n                        vec3 _1279 = -to_light;\n                        float _1286 = _1257.w;\n                        float _1302 = 0.5 / max(dot(_1279, _1261) * (sqrt(max(1.0 - (_1286 * _1286), 0.0)) / max(_1286, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1235.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1279, _1266.xyz) * _1302), 0.5 - (dot(_1279, _1271.xyz) * _1302));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1240.z > 0.5)\n                    {\n                        vec2 param_49 = _1240.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1261;\n                        vec3 param_52 = _1266.xyz;\n                        vec3 param_53 = _1271.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _5629 = _817.xyz * atten;\n    if (_808)\n    {\n        _5629 *= fa_light_tint;\n    }\n    int _1370;\n    if (_834)\n    {\n        _1370 = 0;\n    }\n    else\n    {\n        _1370 = ((_820 > 1.5) && (_820 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _5629, atten, 1.0, dist, _1370);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2153 = fa_shadow_depth(param, param_1);\n    float _2157;\n    if (conv.x < 0.5)\n    {\n        _2157 = _2153;\n    }\n    else\n    {\n        _2157 = (conv.y * conv.z) / (conv.z - (_2153 * (conv.z - conv.y)));\n    }\n    return _2157;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2203 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2209 = vec2(cos(_2203), sin(_2203));\n    vec2 dir = _2209;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2218;\n        if (k < 0.0)\n        {\n            _2218 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2218 = k;\n        }\n        float _2237 = clamp((_2218 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2256 = sqrt((float(i) + 0.5) * 0.0625) * _2237;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2256));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2270 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2270 < (zr - (_2256 * plane)))\n            {\n                sum += _2270;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2298 = sum / cnt;\n        float _2308;\n        if (k < 0.0)\n        {\n            _2308 = (-k) / max(_2298, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2308 = k;\n        }\n        radius = clamp(((max(zr - _2298, 0.0) * unit) * _2308) / texel_m, 1.5, 16.0);\n        dir = _2209;\n    }\n    float lit = 0.0;\n    int _2334 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2334; i_1++)\n    {\n        float _2353 = sqrt((float(i_1) + 0.5) / float(_2334)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2353));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2353 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2334);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2558 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2565;\n    if (!_2558)\n    {\n        _2565 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2565 = _2558;\n    }\n    if (_2565)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2578 = fa_light_texel(param);\n    float _2579 = _2578.x;\n    if (_2579 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2588 = int(_2579 + 0.5);\n    int param_1 = _2588;\n    vec4 _2592 = fa_light_texel(param_1);\n    int param_2 = _2588 + 1;\n    vec4 _2597 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2600 = _2592.y;\n    if (_2600 > 0.0)\n    {\n        float _2617 = 1.0 - smoothstep(0.75 * _2600, _2600, length(world - fa_shadows[27].xyz));\n        fade = _2617;\n        if (_2617 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2592.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2641 = (_2588 + 2) + (face * 6);\n    int param_4 = _2641;\n    int param_5 = _2641 + 1;\n    int param_6 = _2641 + 3;\n    vec4 _2655 = fa_light_texel(param_6);\n    int param_7 = _2641 + 4;\n    vec4 _2660 = fa_light_texel(param_7);\n    int param_8 = _2641 + 5;\n    vec4 _2665 = fa_light_texel(param_8);\n    float _2677 = _2665.x * max(dot(_2655, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2682 = clamp(dot(n, l), 0.0, 1.0);\n    float _2705 = clamp(dot(n, _2655.xyz), -1.0, 1.0);\n    float _2724 = min(sqrt(1.0 - (_2705 * _2705)) / max(abs(dot(n, world - lpos)) / max(dot(_2655, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2727 = _2597.y;\n    float _2729;\n    if (_2727 > 0.0)\n    {\n        _2729 = _2727;\n    }\n    else\n    {\n        _2729 = 1.5 * _2677;\n    }\n    vec4 _2749 = vec4(world + (n * (_2729 * sqrt(1.0 - (_2682 * _2682)))), 1.0);\n    float _2753 = dot(_2655, _2749);\n    float _2756 = _2665.y;\n    if (_2753 < _2756)\n    {\n        return 1.0;\n    }\n    vec2 _2771 = vec2(dot(fa_light_texel(param_4), _2749), dot(fa_light_texel(param_5), _2749)) / vec2(_2753);\n    float _2773 = _2771.x;\n    bool _2776 = _2773 < _2660.x;\n    bool _2785;\n    if (!_2776)\n    {\n        _2785 = _2773 > _2660.z;\n    }\n    else\n    {\n        _2785 = _2776;\n    }\n    bool _2794;\n    if (!_2785)\n    {\n        _2794 = _2771.y < _2660.y;\n    }\n    else\n    {\n        _2794 = _2785;\n    }\n    bool _2803;\n    if (!_2794)\n    {\n        _2803 = _2771.y > _2660.w;\n    }\n    else\n    {\n        _2803 = _2794;\n    }\n    if (_2803)\n    {\n        return 1.0;\n    }\n    float _2809 = _2597.x;\n    float _2811;\n    if (_2809 > 0.0)\n    {\n        _2811 = _2809;\n    }\n    else\n    {\n        _2811 = 1.5 * _2677;\n    }\n    vec2 param_9 = _2771;\n    vec4 param_10 = _2660;\n    float param_11 = _2753 - (_2811 * (1.0 + (0.5 * _2724)));\n    float param_12 = _2677;\n    float param_13 = 1.0;\n    float param_14 = _2665.z * 0.25;\n    float param_15 = (_2677 * min(_2724, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2756, _2665.z);\n    int param_17 = int(_2592.z + 0.5);\n    float param_18 = _2592.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2096;\n    if (i == 0)\n    {\n        _2096 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2112;\n        if (i == 1)\n        {\n            _2112 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2120;\n            if (i == 2)\n            {\n                _2120 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2120 = fa_shadows[24].w;\n            }\n            _2112 = _2120;\n        }\n        _2096 = _2112;\n    }\n    return _2096;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2399 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2404 = clamp(dot(n, l), 0.0, 1.0);\n    float _2410 = sqrt(1.0 - (_2404 * _2404));\n    float _2418 = min(_2410 / max(_2404, 0.20000000298023223876953125), 4.0);\n    float _2423;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2423 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2423 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2448 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2423 * _2410)), 1.0);\n    float _2455 = _2448.x;\n    bool _2458 = _2455 < fa_shadows[ci * 1 + 16].x;\n    bool _2467;\n    if (!_2458)\n    {\n        _2467 = _2455 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2467 = _2458;\n    }\n    bool _2476;\n    if (!_2467)\n    {\n        _2476 = _2448.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2476 = _2467;\n    }\n    bool _2485;\n    if (!_2476)\n    {\n        _2485 = _2448.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2485 = _2476;\n    }\n    bool _2492;\n    if (!_2485)\n    {\n        _2492 = _2448.z > 1.0;\n    }\n    else\n    {\n        _2492 = _2485;\n    }\n    if (_2492)\n    {\n        return -1.0;\n    }\n    float _2500;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2500 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2500 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2448.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2448.z - ((_2500 * (1.0 + (0.5 * _2418))) / _2399);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2399;\n    float param_5 = _2399 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2418, 3.0)) * 0.5) / _2399;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2878 = int(fa_shadows[25].x + 0.5);\n    if (_2878 < 1)\n    {\n        return 1.0;\n    }\n    float _2893 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2878 - 1;\n    if (_2893 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2905 = _2878 > 1;\n    bool _2912;\n    if (_2905)\n    {\n        _2912 = _2893 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2912 = _2905;\n    }\n    if (_2912)\n    {\n        ci = 1;\n    }\n    bool _2916 = _2878 > 2;\n    bool _2923;\n    if (_2916)\n    {\n        _2923 = _2893 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2923 = _2916;\n    }\n    if (_2923)\n    {\n        ci = 2;\n    }\n    bool _2927 = _2878 > 3;\n    bool _2934;\n    if (_2927)\n    {\n        _2934 = _2893 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2934 = _2927;\n    }\n    if (_2934)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2945 = min(_2878, 4);\n    float _2986;\n    for (int c = ci; c < _2945; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2965 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2965;\n            break;\n        }\n        if (_2965 < 0.0)\n        {\n            continue;\n        }\n        s = _2965;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2986 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2986 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3005 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2986, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2893 - (fa_shadow_split_at(param_7) - _3005)) / _3005, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3037;\n        if ((ci + 1) < _2878)\n        {\n            _3037 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3037 = 1.0;\n        }\n        s = mix(s, _3037, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3492 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3499;\n    if (!_3492)\n    {\n        _3499 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3499 = _3492;\n    }\n    if (_3499)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3512 = fa_light_texel(param);\n    float _3513 = _3512.y;\n    float len = _3513;\n    if (_3513 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3525 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3535 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3525);\n    if (_3535 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3541 = len;\n    float _3544 = min(_3541, 0.89999997615814208984375 * dist);\n    len = _3544;\n    float _3550 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3525);\n    float _3555 = _3550 + (0.5 * _3544);\n    vec3 _3561 = world + (gn * _3550);\n    float _3563 = fa_shadow_noise();\n    float occ = 0.0;\n    float _3628;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3579 = (float(k) + _3563) * 0.083333335816860198974609375;\n        vec3 _3587 = _3561 + (l * (_3579 * len));\n        vec4 _3593 = vec4(_3587, 1.0);\n        float _3599 = dot(fa_mesh_fs_params[28], _3593);\n        if (_3599 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _3619 = vec2(dot(fa_mesh_fs_params[26], _3593), dot(fa_mesh_fs_params[27], _3593)) / vec2(_3599);\n        float _3623 = _3619.x * 0.5;\n        float _3624 = _3623 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _3628 = (_3619.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3628 = 0.5 - (_3619.y * 0.5);\n        }\n        bool _3644 = _3624 < 0.0;\n        bool _3651;\n        if (!_3644)\n        {\n            _3651 = _3624 >= 1.0;\n        }\n        else\n        {\n            _3651 = _3644;\n        }\n        bool _3658;\n        if (!_3651)\n        {\n            _3658 = _3628 < 0.0;\n        }\n        else\n        {\n            _3658 = _3651;\n        }\n        bool _3665;\n        if (!_3658)\n        {\n            _3665 = _3628 >= 1.0;\n        }\n        else\n        {\n            _3665 = _3658;\n        }\n        if (_3665)\n        {\n            break;\n        }\n        vec4 _3692 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3624, _3628) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_3692.w < 0.5)\n        {\n            continue;\n        }\n        float _3711 = (dot(fa_mesh_fs_params[29].xyz, _3587) + fa_mesh_fs_params[29].w) - _3692.x;\n        if ((_3711 > _3550) && (_3711 < _3555))\n        {\n            occ = max(occ, (1.0 - (_3579 * _3579)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_3624, 0.5 - _3623), min(_3628, 1.0 - _3628))));\n        }\n    }\n    return 1.0 - (occ * _3535);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _3814 = fa_baked_keep(param);\n    if (_3814 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3840 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _5655 = _3840.color;\n    float _5656 = _3840.attenuation;\n    float _5657 = _3840.shadow;\n    bool _3843 = _3840.type == 0;\n    if (_3843 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3840.direction;\n        float _3854 = fa_shadow_factor(param_5, param_6);\n        _5657 = _3854;\n        _5655 *= _3854;\n    }\n    else\n    {\n        bool _3865 = _3840.type != 0;\n        bool _3871;\n        if (_3865)\n        {\n            _3871 = _5656 > 0.0;\n        }\n        else\n        {\n            _3871 = _3865;\n        }\n        if (_3871)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _3840.direction;\n            float _3890 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5657 = _3890;\n            _5655 *= _3890;\n        }\n    }\n    bool _3900 = fa_mesh_fs_params[24].x > 0.5;\n    bool _3906;\n    if (_3900)\n    {\n        _3906 = _5656 > 0.0;\n    }\n    else\n    {\n        _3906 = _3900;\n    }\n    if (_3906)\n    {\n        float _3913;\n        if (_3843)\n        {\n            _3913 = 1000000000.0;\n        }\n        else\n        {\n            _3913 = _3840._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _3840.direction;\n        float param_18 = _3913;\n        float _3931 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5657 *= _3931;\n        _5655 *= _3931;\n    }\n    float _3944 = _5656;\n    float _3945 = _3944 * _3814;\n    _5656 = _3945;\n    vec3 _3949 = _5655;\n    vec3 _3950 = _3949 * _3814;\n    _5655 = _3950;\n    return LightSample(_3840.direction, _3950, _3945, _5657, _3840._distance, _3840.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3065 = int(fa_shadows[25].x + 0.5);\n    float _3075 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3080 = _3065 > 0;\n    bool _3089;\n    if (_3080)\n    {\n        int param = _3065 - 1;\n        _3089 = _3075 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3089 = _3080;\n    }\n    if (_3089)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3095 = _3065 > 1;\n        bool _3102;\n        if (_3095)\n        {\n            _3102 = _3075 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3102 = _3095;\n        }\n        if (_3102)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3108 = _3065 > 2;\n        bool _3115;\n        if (_3108)\n        {\n            _3115 = _3075 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3115 = _3108;\n        }\n        if (_3115)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3121 = _3065 > 3;\n        bool _3128;\n        if (_3121)\n        {\n            _3128 = _3075 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3128 = _3121;\n        }\n        if (_3128)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5447 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5447 = -_5447;\n    }\n    vec3 _5020 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5447, fa_world_tangent, fa_uv, fa_vertex_color, _5020, gl_FrontFacing);\n    Surface _5028 = fa_standard_surface(param_1);\n    vec3 _5486 = _5028.albedo;\n    float _5487 = _5028.alpha;\n    vec3 _5488 = _5028.normal;\n    float _5489 = _5028.metallic;\n    float _5490 = _5028.roughness;\n    float _5491 = _5028.occlusion;\n    vec3 _5492 = _5028.emission;\n    float _5493 = _5028.clearcoat;\n    float _5494 = _5028.clearcoat_roughness;\n    vec3 _5495 = _5028.sheen_color;\n    float _5496 = _5028.sheen_roughness;\n    float _5497 = _5028.anisotropy;\n    float _5498 = _5028.anisotropy_rotation;\n    float _5499 = _5028.specular;\n    float _5500 = _5028.ior;\n    vec3 _5501 = _5028.specular_color;\n    float _5502 = _5028.transmission;\n    float _5503 = _5028.thickness;\n    vec3 _5504 = _5028.attenuation_color;\n    float _5505 = _5028.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5447, fa_world_tangent, fa_uv, fa_vertex_color, _5020, gl_FrontFacing);\n    Surface param_3 = _5028;\n    surface(param_2, param_3);\n    _5486 = param_3.albedo;\n    _5487 = param_3.alpha;\n    _5488 = param_3.normal;\n    _5489 = param_3.metallic;\n    _5490 = param_3.roughness;\n    _5491 = param_3.occlusion;\n    _5492 = param_3.emission;\n    _5493 = param_3.clearcoat;\n    _5494 = param_3.clearcoat_roughness;\n    _5495 = param_3.sheen_color;\n    _5496 = param_3.sheen_roughness;\n    _5497 = param_3.anisotropy;\n    _5498 = param_3.anisotropy_rotation;\n    _5499 = param_3.specular;\n    _5500 = param_3.ior;\n    _5501 = param_3.specular_color;\n    _5502 = param_3.transmission;\n    _5503 = param_3.thickness;\n    _5504 = param_3.attenuation_color;\n    _5505 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5447;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5486 = param_6;\n    _5488 = param_7;\n    fa_lod_dither();\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5486;\n    }\n    else\n    {\n        vec3 _5068 = _5488;\n        vec3 _5069 = normalize(_5068);\n        _5488 = _5069;\n        vec3 param_8 = _5069;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _5447, fa_world_tangent, fa_uv, fa_vertex_color, _5020, gl_FrontFacing);\n        Surface param_10 = Surface(_5486, _5487, _5488, _5489, _5490, _5491, _5492, _5493, _5494, _5495, _5496, _5497, _5498, _5499, _5500, _5501, _5502, _5503, _5504, _5505);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _5088 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5088; ln++)\n        {\n            int param_12 = ln;\n            int _5101 = fa_cl_light(param_12);\n            int param_13 = _5101;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _5101;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _5447;\n            LightSample _5117 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _5447, fa_world_tangent, fa_uv, fa_vertex_color, _5020, gl_FrontFacing);\n            Surface param_18 = Surface(_5486, _5487, _5488, _5489, _5490, _5491, _5492, _5493, _5494, _5495, _5496, _5497, _5498, _5499, _5500, _5501, _5502, _5503, _5504, _5505);\n            LightSample param_19 = _5117;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _5132 = result;\n    vec3 _5133 = _5132 + _5492;\n    result = _5133;\n    vec3 param_20 = _5133;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _5142 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5149;\n    if (!_5142)\n    {\n        _5149 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5149 = _5142;\n    }\n    if (_5149)\n    {\n        vec3 _5158 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5164 = dot(_5158, fa_mesh_fs_params[9].xyz);\n        bool _5168 = fa_mesh_fs_params[9].w > 0.5;\n        float _5169;\n        if (_5168)\n        {\n            _5169 = _5164;\n        }\n        else\n        {\n            _5169 = length(_5158);\n        }\n        float _5181 = _5169 - fa_mesh_fs_params[8].x;\n        if (_5181 > 0.0)\n        {\n            float _5190 = fa_mesh_fs_params[7].w * _5181;\n            float tau = _5190 * _5190;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5206;\n                if (_5168)\n                {\n                    _5206 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5164);\n                }\n                else\n                {\n                    _5206 = fa_mesh_fs_params[0].y;\n                }\n                float _5227 = mix(_5206, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5169, 0.0, 1.0));\n                float _5231 = fa_world_pos.y - _5227;\n                float _5236 = _5227 - fa_mesh_fs_params[8].z;\n                float _5241 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5244 = _5236 <= 0.0;\n                bool _5245 = !_5244;\n                bool _5251;\n                if (_5245)\n                {\n                    _5251 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5251 = _5244;\n                }\n                float _5252;\n                if (_5251)\n                {\n                    _5252 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5252 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5236, 80.0));\n                }\n                bool _5279;\n                if (_5245)\n                {\n                    _5279 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5279 = _5244;\n                }\n                float _5280;\n                if (_5279)\n                {\n                    _5280 = fa_mesh_fs_params[8].y * _5236;\n                }\n                else\n                {\n                    _5280 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5236, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5305 = _5241 <= 0.0;\n                bool _5312;\n                if (!_5305)\n                {\n                    _5312 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5312 = _5305;\n                }\n                float _5313;\n                if (_5312)\n                {\n                    _5313 = fa_mesh_fs_params[8].y * _5241;\n                }\n                else\n                {\n                    _5313 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5241, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5340;\n                if (abs(_5231) < 0.001000000047497451305389404296875)\n                {\n                    _5340 = _5252;\n                }\n                else\n                {\n                    _5340 = (_5313 - _5280) / _5231;\n                }\n                tau += (_5181 * max(_5340, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5487);\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_372",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
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
            "inst_name": "_2106",
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
              "name": "fa_probe_atlas",
              "multisampled": false,
              "type": "2d",
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
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _218 = fa_linear_to_srgb(param);\n        c = _218;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _227 = fa_srgb_to_linear(param_1);\n            c = _227;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _58;\n    if (i.front_facing)\n    {\n        _58 = i.world_normal;\n    }\n    else\n    {\n        _58 = -i.world_normal;\n    }\n    vec3 _83 = normalize(i.world_tangent.xyz - (_58 * dot(_58, i.world_tangent.xyz)));\n    vec3 _111 = normalize(((_83 * m.x) + ((cross(_58, _83) * i.world_tangent.w) * m.y)) + (_58 * m.z));\n    vec3 _114;\n    if (i.front_facing)\n    {\n        _114 = _111;\n    }\n    else\n    {\n        _114 = -_111;\n    }\n    return _114;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _267 = fa_tex_fix(param_2, param_3);\n    vec4 _868 = base_t;\n    _868.x = _267.x;\n    _868.y = _267.y;\n    _868.z = _267.z;\n    base_t = _868;\n    vec4 _283 = (_868 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _823 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _317 = fa_tex_fix(param_6, param_7);\n        vec3 _321 = (_317 * 2.0) - vec3(1.0);\n        vec2 _326 = _321.xy * fa_mesh_fs_params[6].x;\n        vec3 _876 = _321;\n        _876.x = _326.x;\n        _876.y = _326.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _876;\n        _823 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _355 = fa_tex_fix(param_12, param_13);\n    vec4 _879 = mrt;\n    _879.x = _355.x;\n    _879.y = _355.y;\n    _879.z = _355.z;\n    mrt = _879;\n    vec4 _385 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _385.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _397 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _427 = fa_tex_fix(param_20, param_21);\n    float _828 = fa_mesh_fs_params[20].x;\n    float _829 = fa_mesh_fs_params[20].y;\n    float _832 = fa_mesh_fs_params[20].z;\n    float _831 = fa_mesh_fs_params[21].w;\n    float _834 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _828 *= _397.y;\n            _829 *= _397.z;\n            _831 *= _385.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _832 *= mrt.x;\n            _834 *= mrt.w;\n        }\n    }\n    return Surface(_283.xyz, _283.w, _823, clamp(fa_mesh_fs_params[5].x * _355.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _355.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_397.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _427), _828, _829, fa_mesh_fs_params[21].xyz, _831, _832, fa_mesh_fs_params[20].w, _834, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _151 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _154;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _154 = _151 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _154 = _151 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_154)\n        {\n            discard;\n        }\n    }\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _718 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _718 = -_718;\n    }\n    vec3 _579 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _718, fa_world_tangent, fa_uv, fa_vertex_color, _579, gl_FrontFacing);\n    Surface _584 = fa_standard_surface(param);\n    vec3 _742 = _584.normal;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _718, fa_world_tangent, fa_uv, fa_vertex_color, _579, gl_FrontFacing);\n    Surface param_2 = _584;\n    surface(param_1, param_2);\n    _742 = param_2.normal;\n    fa_lod_dither();\n    vec3 _595 = normalize(_742);\n    vec3 _610 = normalize(vec3(dot(fa_pre_r0, _595), dot(fa_pre_r1, _595), dot(fa_pre_r2, _595)));\n    float _622 = _610.z;\n    vec2 e = _610.xy / vec2((abs(_610.x) + abs(_610.y)) + abs(_622));\n    if (_622 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_129",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _218 = fa_linear_to_srgb(param);\n        c = _218;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _227 = fa_srgb_to_linear(param_1);\n            c = _227;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _58;\n    if (i.front_facing)\n    {\n        _58 = i.world_normal;\n    }\n    else\n    {\n        _58 = -i.world_normal;\n    }\n    vec3 _83 = normalize(i.world_tangent.xyz - (_58 * dot(_58, i.world_tangent.xyz)));\n    vec3 _111 = normalize(((_83 * m.x) + ((cross(_58, _83) * i.world_tangent.w) * m.y)) + (_58 * m.z));\n    vec3 _114;\n    if (i.front_facing)\n    {\n        _114 = _111;\n    }\n    else\n    {\n        _114 = -_111;\n    }\n    return _114;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _267 = fa_tex_fix(param_2, param_3);\n    vec4 _868 = base_t;\n    _868.x = _267.x;\n    _868.y = _267.y;\n    _868.z = _267.z;\n    base_t = _868;\n    vec4 _283 = (_868 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _823 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _317 = fa_tex_fix(param_6, param_7);\n        vec3 _321 = (_317 * 2.0) - vec3(1.0);\n        vec2 _326 = _321.xy * fa_mesh_fs_params[6].x;\n        vec3 _876 = _321;\n        _876.x = _326.x;\n        _876.y = _326.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _876;\n        _823 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _355 = fa_tex_fix(param_12, param_13);\n    vec4 _879 = mrt;\n    _879.x = _355.x;\n    _879.y = _355.y;\n    _879.z = _355.z;\n    mrt = _879;\n    vec4 _385 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _385.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _397 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _427 = fa_tex_fix(param_20, param_21);\n    float _828 = fa_mesh_fs_params[20].x;\n    float _829 = fa_mesh_fs_params[20].y;\n    float _832 = fa_mesh_fs_params[20].z;\n    float _831 = fa_mesh_fs_params[21].w;\n    float _834 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _828 *= _397.y;\n            _829 *= _397.z;\n            _831 *= _385.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _832 *= mrt.x;\n            _834 *= mrt.w;\n        }\n    }\n    return Surface(_283.xyz, _283.w, _823, clamp(fa_mesh_fs_params[5].x * _355.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _355.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_397.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _427), _828, _829, fa_mesh_fs_params[21].xyz, _831, _832, fa_mesh_fs_params[20].w, _834, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _151 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _154;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _154 = _151 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _154 = _151 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_154)\n        {\n            discard;\n        }\n    }\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _718 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _718 = -_718;\n    }\n    vec3 _579 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _718, fa_world_tangent, fa_uv, fa_vertex_color, _579, gl_FrontFacing);\n    Surface _584 = fa_standard_surface(param);\n    vec3 _742 = _584.normal;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _718, fa_world_tangent, fa_uv, fa_vertex_color, _579, gl_FrontFacing);\n    Surface param_2 = _584;\n    surface(param_1, param_2);\n    _742 = param_2.normal;\n    fa_lod_dither();\n    vec3 _595 = normalize(_742);\n    vec3 _610 = normalize(vec3(dot(fa_pre_r0, _595), dot(fa_pre_r1, _595), dot(fa_pre_r2, _595)));\n    float _622 = _610.z;\n    vec2 e = _610.xy / vec2((abs(_610.x) + abs(_610.y)) + abs(_622));\n    if (_622 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_129",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
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
