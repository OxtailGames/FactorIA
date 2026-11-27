{
  "format": "factoria.shader/1",
  "engine": "0.39.0",
  "template": "4694fb4be9bed2a7c5475af904870ae4995eb283e1c27e15e0192dfe0c2b2256",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4774[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat fa_rt_slope;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1445 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1452;\n    if (!_1445)\n    {\n        _1452 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1452 = _1445;\n    }\n    bool _1460;\n    if (!_1452)\n    {\n        _1460 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1460 = _1452;\n    }\n    bool _1467;\n    if (!_1460)\n    {\n        _1467 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1467 = _1460;\n    }\n    bool _1474;\n    if (!_1467)\n    {\n        _1474 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1474 = _1467;\n    }\n    if (_1474)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1484 = vec4(world_pos, 1.0);\n    float _1490 = dot(fa_mesh_fs_params[16], _1484);\n    if (!(_1490 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1512 = vec2(dot(fa_mesh_fs_params[14], _1484), dot(fa_mesh_fs_params[15], _1484)) / vec2(_1490);\n    int _1516 = int(fa_mesh_fs_params[18].x);\n    int _1520 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1520) + clamp(int(floor(((_1512.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1520 - 1)) * _1516)) + clamp(int(floor(((_1512.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1516 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1596 = fa_cluster_texel(param);\n    return ivec2(int(_1596.x), int(_1596.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    float _5589 = dot(fa_mesh_fs_params[29].xyz, world_pos) + fa_mesh_fs_params[29].w;\n    float _5592 = fwidth(_5589);\n    bool _5595 = fa_mesh_fs_params[25].y > 0.5;\n    bool _5602;\n    if (!_5595)\n    {\n        _5602 = fa_mesh_fs_params[25].w > 0.5;\n    }\n    else\n    {\n        _5602 = _5595;\n    }\n    if (_5602)\n    {\n        fa_rt_slope = min(1.5 * _5592, 0.100000001490116119384765625 * _5589);\n    }\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5618 = fa_cluster_lookup(param);\n    fa_cl_slot = _5618.x;\n    fa_cl_local = _5618.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5830 = fa_linear_to_srgb(param);\n        c = _5830;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5838 = fa_srgb_to_linear(param_1);\n            c = _5838;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _400;\n    if (i.front_facing)\n    {\n        _400 = i.world_normal;\n    }\n    else\n    {\n        _400 = -i.world_normal;\n    }\n    vec3 _424 = normalize(i.world_tangent.xyz - (_400 * dot(_400, i.world_tangent.xyz)));\n    vec3 _451 = normalize(((_424 * m.x) + ((cross(_400, _424) * i.world_tangent.w) * m.y)) + (_400 * m.z));\n    vec3 _454;\n    if (i.front_facing)\n    {\n        _454 = _451;\n    }\n    else\n    {\n        _454 = -_451;\n    }\n    return _454;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5870 = fa_tex_fix(param_2, param_3);\n    vec4 _7861 = base_t;\n    _7861.x = _5870.x;\n    _7861.y = _5870.y;\n    _7861.z = _5870.z;\n    base_t = _7861;\n    vec4 _5884 = (_7861 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _7643 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5918 = fa_tex_fix(param_6, param_7);\n        vec3 _5921 = (_5918 * 2.0) - vec3(1.0);\n        vec2 _5926 = _5921.xy * fa_mesh_fs_params[6].x;\n        vec3 _7869 = _5921;\n        _7869.x = _5926.x;\n        _7869.y = _5926.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7869;\n        _7643 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5956 = fa_tex_fix(param_12, param_13);\n    vec4 _7872 = mrt;\n    _7872.x = _5956.x;\n    _7872.y = _5956.y;\n    _7872.z = _5956.z;\n    mrt = _7872;\n    vec4 _5986 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5986.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5997 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _6029 = fa_tex_fix(param_20, param_21);\n    float _7648 = fa_mesh_fs_params[20].x;\n    float _7649 = fa_mesh_fs_params[20].y;\n    float _7652 = fa_mesh_fs_params[20].z;\n    float _7651 = fa_mesh_fs_params[21].w;\n    float _7654 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _7648 *= _5997.y;\n            _7649 *= _5997.z;\n            _7651 *= _5986.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _7652 *= mrt.x;\n            _7654 *= mrt.w;\n        }\n    }\n    return Surface(_5884.xyz, _5884.w, _7643, clamp(fa_mesh_fs_params[5].x * _5956.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5956.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5997.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _6029), _7648, _7649, fa_mesh_fs_params[21].xyz, _7651, _7652, fa_mesh_fs_params[20].w, _7654, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1676 = rect.zw - rect.xy;\n    vec2 _1680 = _1676 * atlas;\n    vec2 _1684 = ddx * _1680;\n    vec2 _1688 = ddy * _1680;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1676), clamp(0.5 * log2(max(max(dot(_1684, _1684), dot(_1688, _1688)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1721 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1728;\n    if (!_1721)\n    {\n        _1728 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1728 = _1721;\n    }\n    if (_1728)\n    {\n        return;\n    }\n    vec3 _1734 = dFdx(world_pos);\n    vec3 _1737 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1741 = fa_cluster_texel(param);\n    int _1745 = int(_1741.w);\n    if (_1745 < 1)\n    {\n        return;\n    }\n    int _1755 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1755;\n    vec4 _1759 = fa_light_texel(param_1);\n    vec2 _1762 = _1759.yz;\n    int _1766 = int(_1759.w);\n    int param_2 = _1755 + 1;\n    vec4 _1771 = fa_light_texel(param_2);\n    float _1772 = _1771.x;\n    int _1778 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1782 = int(_1741.z);\n    vec3 _2047;\n    for (int k = 0; k < _1745; k++)\n    {\n        int _1795 = _1782 + k;\n        int param_3 = _1766 + (_1795 >> 2);\n        int _1812 = (_1755 + 2) + (int(fa_light_texel(param_3)[_1795 & 3]) * 7);\n        int param_4 = _1812 + 6;\n        vec4 _1817 = fa_light_texel(param_4);\n        if (((int(_1817.w + 0.5) >> _1778) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1812;\n        vec4 _1832 = fa_light_texel(param_5);\n        int param_6 = _1812 + 1;\n        vec4 _1837 = fa_light_texel(param_6);\n        int param_7 = _1812 + 2;\n        vec4 _1842 = fa_light_texel(param_7);\n        vec3 _1845 = _1832.xyz;\n        float _1850 = dot(_1845, world_pos) + _1832.w;\n        vec3 _1852 = _1837.xyz;\n        float _1857 = dot(_1852, world_pos) + _1837.w;\n        vec3 _1859 = _1842.xyz;\n        float _1864 = dot(_1859, world_pos) + _1842.w;\n        bool _1869 = abs(_1850) > 0.5;\n        bool _1877;\n        if (!_1869)\n        {\n            _1877 = abs(_1857) > 0.5;\n        }\n        else\n        {\n            _1877 = _1869;\n        }\n        bool _1885;\n        if (!_1877)\n        {\n            _1885 = abs(_1864) > 0.5;\n        }\n        else\n        {\n            _1885 = _1877;\n        }\n        if (_1885)\n        {\n            continue;\n        }\n        float _1900 = clamp(dot(geo_normal, normalize(_1859)) * _1817.z, 0.0, 1.0);\n        if (_1900 <= 0.0)\n        {\n            continue;\n        }\n        float _1920 = (clamp((0.5 - abs(_1864)) * 10.0, 0.0, 1.0) * _1900) * _1817.x;\n        vec2 _1928 = vec2(_1850 + 0.5, 0.5 - _1857);\n        vec2 _1938 = vec2(dot(_1845, _1734), dot(_1852, _1734));\n        vec2 _1948 = vec2(dot(_1845, _1737), dot(_1852, _1737));\n        int param_8 = _1812 + 5;\n        vec4 _1953 = fa_light_texel(param_8);\n        int param_9 = _1812 + 3;\n        vec4 _1958 = fa_light_texel(param_9);\n        int param_10 = _1812 + 4;\n        vec4 _1963 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1953.xyz;\n        bool _1973 = _1958.z > _1958.x;\n        if (_1973)\n        {\n            vec4 param_11 = _1958;\n            vec2 param_12 = _1928;\n            vec2 param_13 = _1762;\n            vec2 param_14 = _1938;\n            vec2 param_15 = _1948;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1772 > 0.5) && (_1772 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1999 = fa_dc_to_linear(param_16);\n                vec4 _7731 = tx;\n                _7731.x = _1999.x;\n                _7731.y = _1999.y;\n                _7731.z = _1999.z;\n                tx = _7731;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1920 * tex_a) * _1953.w, 0.0, 1.0)));\n        if (_1963.z > _1963.x)\n        {\n            vec4 param_17 = _1963;\n            vec2 param_18 = _1928;\n            vec2 param_19 = _1762;\n            vec2 param_20 = _1938;\n            vec2 param_21 = _1948;\n            vec4 _2043 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1772 > 1.5)\n            {\n                vec3 param_22 = _2043.xyz;\n                vec3 _2053 = fa_dc_to_srgb(param_22);\n                _2047 = _2053;\n            }\n            else\n            {\n                _2047 = _2043.xyz;\n            }\n            vec3 _2062 = (_2047 * 2.0) - vec3(1.0);\n            vec2 _2067 = _2062.xy * _1817.y;\n            vec3 _2089 = (normalize(_1845) * _2067.x) + (normalize(_1852) * _2067.y);\n            vec3 _2092 = normalize(normal);\n            normal = normalize(mix(_2092, normalize((_2092 * max(_2062.z, 0.0500000007450580596923828125)) + (_2089 - (_2092 * dot(_2092, _2089)))), vec3(clamp(_1920 * (_1973 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3869 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3869;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4480 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4485 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4480 > 0.0005000000237487256526947021484375)\n    {\n        if (_4485)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4480;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4480;\n        }\n    }\n    bool _4536 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4536)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4567 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4567)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4485 || _4536) || _4567)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3889 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3892 = _3889.x;\n    float _3894 = _3889.z;\n    vec2 e = vec2(_3892, _3894);\n    if (_3889.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3894)) * ((_3892 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3892)) * ((_3894 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _6141 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _6146 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _6151 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _6156 = fa_light_texel(param_3);\n    bool _6159 = _6156.z < 0.5;\n    bool _6167;\n    if (!_6159)\n    {\n        _6167 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _6167 = _6159;\n    }\n    if (_6167)\n    {\n        return vec3(0.0);\n    }\n    float _6174 = max(_6141.w, 9.9999997473787516355514526367188e-05);\n    vec3 _6177 = _6146.xyz;\n    vec3 _6181 = _6141.xyz;\n    vec3 _6185 = (fa_world_pos - _6181) / vec3(_6174);\n    vec3 _6194 = min(_6185 + vec3(0.5), (_6177 - vec3(0.5)) - _6185);\n    float _6203 = min(_6194.x, min(_6194.y, _6194.z));\n    if (!(_6203 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6218 = _6177 - vec3(1.0);\n    vec3 _6219 = clamp(_6185, vec3(0.0), _6218);\n    vec3 _6227 = min(floor(_6219), max(_6177 - vec3(2.0), vec3(0.0)));\n    vec3 _6231 = _6219 - _6227;\n    vec3 _6242 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _6174));\n    int _6247 = int(_6151.y + 0.5);\n    float _6252 = 0.3257350027561187744140625 * n.y;\n    float _6256 = 0.3257350027561187744140625 * n.z;\n    float _6260 = 0.3257350027561187744140625 * n.x;\n    float _6267 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _6274 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _6283 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _6290 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _6303 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _6310 = 8 + int(_6156.w);\n    float _6337;\n    float _6350;\n    float _6364;\n    for (int k = 0; k < _6310; k++)\n    {\n        float _6323 = float(k & 1);\n        float _6327 = float((k >> 1) & 1);\n        float _6331 = float((k >> 2) & 1);\n        if (_6323 > 0.5)\n        {\n            _6337 = _6231.x;\n        }\n        else\n        {\n            _6337 = 1.0 - _6231.x;\n        }\n        if (_6327 > 0.5)\n        {\n            _6350 = _6231.y;\n        }\n        else\n        {\n            _6350 = 1.0 - _6231.y;\n        }\n        if (_6331 > 0.5)\n        {\n            _6364 = _6231.z;\n        }\n        else\n        {\n            _6364 = 1.0 - _6231.z;\n        }\n        float _6374 = (_6337 * _6350) * _6364;\n        if (!(_6374 > 0.0))\n        {\n            continue;\n        }\n        vec3 _6387 = min(_6227 + vec3(_6323, _6327, _6331), _6218);\n        int _6407 = int(((_6151.x + _6387.x) + (_6146.x * (_6387.y + (_6146.y * _6387.z)))) + 0.5);\n        vec2 _6422 = vec2(float(_6407 % _6247) * 10.0, 1024.0 + (float(_6407 / _6247) * 11.0));\n        vec2 param_4 = _6422 + vec2(9.5, 10.5);\n        vec4 _6430 = fa_gi_fetch(param_4);\n        bool _6433 = _6430.y < 0.5;\n        bool _6442;\n        if (!_6433)\n        {\n            _6442 = _6430.x > _6156.y;\n        }\n        else\n        {\n            _6442 = _6433;\n        }\n        if (_6442)\n        {\n            continue;\n        }\n        vec3 _6454 = _6242 - (_6181 + (_6387 * _6174));\n        float _6457 = length(_6454);\n        vec3 _6463 = _6454 / vec3(max(_6457, 9.9999997473787516355514526367188e-05));\n        float _6473 = max(9.9999997473787516355514526367188e-05, (dot(-_6463, n) + 1.0) * 0.5);\n        float w = _6374 * (_6473 * _6473);\n        vec3 param_5 = _6463;\n        vec2 param_6 = (_6422 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _6492 = fa_gi_fetch(param_6);\n        float _6499 = _6457 / max(_6151.z, 9.9999997473787516355514526367188e-05);\n        float _6502 = _6492.x;\n        if (_6499 > _6502)\n        {\n            float _6515 = max(_6492.y - (_6502 * _6502), 0.0);\n            float _6520 = _6499 - _6502;\n            float _6529 = _6515 / max(_6515 + (_6520 * _6520), 9.9999999600419720025001879548654e-13);\n            w *= ((_6529 * _6529) * _6529);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _6422 + vec2(0.5, 10.5);\n        vec2 param_8 = _6422 + vec2(1.5, 10.5);\n        vec2 param_9 = _6422 + vec2(2.5, 10.5);\n        vec2 param_10 = _6422 + vec2(3.5, 10.5);\n        vec2 param_11 = _6422 + vec2(4.5, 10.5);\n        vec2 param_12 = _6422 + vec2(5.5, 10.5);\n        vec2 param_13 = _6422 + vec2(6.5, 10.5);\n        vec2 param_14 = _6422 + vec2(7.5, 10.5);\n        vec2 param_15 = _6422 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _6252)) + (fa_gi_fetch(param_9).xyz * _6256)) + (fa_gi_fetch(param_10).xyz * _6260)) + (fa_gi_fetch(param_11).xyz * _6267)) + (fa_gi_fetch(param_12).xyz * _6274)) + (fa_gi_fetch(param_13).xyz * _6283)) + (fa_gi_fetch(param_14).xyz * _6290)) + (fa_gi_fetch(param_15).xyz * _6303)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_6203 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _6655;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _6655 = _6156.x;\n    }\n    else\n    {\n        _6655 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_6151.w * _6655);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _6679 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _6684 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _6689 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _6689) && (k < 8); k++)\n    {\n        int param = _6684 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _6679;\n        vec3 _6714 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _6719 = param_3 * left;\n        acc += (_6714 * _6719);\n        left -= _6719;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _6748 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _6748;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[53].x > 0.5)\n    {\n        vec4 _6790 = vec4(fa_world_pos, 1.0);\n        vec2 _6809 = vec2(dot(fa_mesh_fs_params[26], _6790), dot(fa_mesh_fs_params[27], _6790)) / vec2(max(dot(fa_mesh_fs_params[28], _6790), 9.9999997473787516355514526367188e-05));\n        float _6818;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _6818 = (_6809.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _6818 = 0.5 - (_6809.y * 0.5);\n        }\n        return texelFetch(fa_lightmap_fa_env_smp, clamp(ivec2(vec2((_6809.x * 0.5) + 0.5, _6818) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4699 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4707 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4710 = int(_4699);\n    int _4713 = int(_4707);\n    float _4723 = _4707 - float(_4713);\n    int _4778 = (_4710 * 9) + _4713;\n    int _4798 = ((_4710 + 1) * 9) + _4713;\n    return mix(mix(_4774[_4778], _4774[_4778 + 1], _4723), mix(_4774[_4798], _4774[_4798 + 1], _4723), _4699 - float(_4710));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _7502 = false;\n    float _7503 = 1.0;\n    float _7504 = 1.0;\n    float _7505 = 1.0;\n    float _7506 = 0.0;\n    float _7507 = 0.0;\n    float _7508 = 0.0;\n    float _7509 = 0.0;\n    float _7511 = 1.0;\n    bool _7512 = false;\n    vec3 _7513 = vec3(0.0);\n    float _7514 = 1.0;\n    float _7515 = 1.0;\n    float _7516 = 1.0;\n    float _7517 = 0.0;\n    float _7518 = 0.0;\n    vec3 _7519 = vec3(1.0, 0.0, 0.0);\n    vec3 _7520 = vec3(0.0, 0.0, 1.0);\n    float _7521 = 1.0;\n    float _7522 = 1.0;\n    float _4849 = clamp(s.specular, 0.0, 1.0);\n    float _4853 = clamp(s.ior, 1.0, 3.0);\n    bool _4858 = (_4849 != 1.0) || (_4853 != 1.5);\n    bool _4867;\n    if (!_4858)\n    {\n        _4867 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4867 = _4858;\n    }\n    if (_4867)\n    {\n        float _4875 = (_4853 - 1.0) / (_4853 + 1.0);\n        f0 = mix(min(vec3(_4875 * _4875) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4849, s.albedo, vec3(metallic));\n        _7503 = mix(_4849, 1.0, metallic);\n        _7502 = true;\n    }\n    float _4902 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4902 > 0.0)\n    {\n        float _4910 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _7506 = _4902;\n        _7507 = _4910;\n        float _4917 = _4910 * _4910;\n        _7508 = _4917;\n        _7509 = _4917 * _4917;\n        float _4929 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _7511 = _4929;\n        _7504 = 1.0 - (_4902 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4929, 0.0, 1.0), 5.0))));\n        _7502 = true;\n    }\n    vec3 _4948 = max(s.sheen_color, vec3(0.0));\n    float _4957 = max(_4948.x, max(_4948.y, _4948.z));\n    if (_4957 > 0.0)\n    {\n        float _4965 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _7512 = true;\n        _7513 = _4948;\n        _7514 = _4965;\n        _7515 = _4965 * _4965;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4965;\n        float _4982 = fa_sheen_albedo(param, param_1);\n        _7517 = _4982;\n        _7516 = 1.0 - min(_4957 * _4982, 1.0);\n        _7502 = true;\n    }\n    _7505 = _7504 * _7516;\n    float _5001 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_5001 != 0.0)\n    {\n        vec3 _5016 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _5016;\n        if (dot(_5016, _5016) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _5028 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_5028.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _5028.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _5028.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _5032 = t;\n        vec3 _5033 = normalize(_5032);\n        t = _5033;\n        vec3 _5058 = normalize((_5033 * cos(s.anisotropy_rotation)) + ((cross(n, _5033) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _7519 = _5058;\n        _7520 = cross(n, _5058);\n        float _5068 = roughness * roughness;\n        float _5074 = mix(_5068, 1.0, _5001 * _5001);\n        bool _5076 = _5001 > 0.0;\n        _7521 = _5076 ? _5074 : _5068;\n        _7522 = _5076 ? _5068 : _5074;\n        _7518 = _5001;\n        _7502 = true;\n    }\n    return FaLayers(_7502, _7503, _7504, _7505, _7506, _7507, _7508, _7509, i.world_normal, _7511, _7512, _7513, _7514, _7515, _7516, _7517, _7518, _7519, _7520, _7521, _7522);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4631 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4634 = _4631.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4634 * _4634, exp2((-9.27999973297119140625) * ndv)) * _4634) + _4631.y)) + _4631.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3941;\n    if (lv == 0)\n    {\n        _3941 = 0.0;\n    }\n    else\n    {\n        _3941 = res + 2.0;\n    }\n    float _3951;\n    if (lv == 0)\n    {\n        _3951 = 0.0;\n    }\n    else\n    {\n        _3951 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3941, _3951)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3997;\n    if (res > 64.5)\n    {\n        _3997 = 5.0;\n    }\n    else\n    {\n        _3997 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _4012 = clamp(rough, 0.0, 1.0) * (_3997 - 1.0);\n    int _4019 = int(min(floor(_4012), _3997 - 2.0));\n    float _4024 = _4012 - float(_4019);\n    vec3 param = d;\n    vec2 _4028 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _4019;\n    vec2 param_4 = _4028;\n    vec3 _4038 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_4024 < 0.00200000009499490261077880859375)\n    {\n        return _4038;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _4019 + 1;\n    vec2 param_8 = _4028;\n    return mix(_4038, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_4024));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _4109 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _4116 = dot(by.xyz, fa_world_pos) + by.w;\n    float _4123 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _4129 = dot(bx.xyz, d);\n    float _4133 = dot(by.xyz, d);\n    float _4137 = dot(bz.xyz, d);\n    float _4143;\n    if (_4129 > 9.9999999747524270787835121154785e-07)\n    {\n        _4143 = (1.0 - _4109) / _4129;\n    }\n    else\n    {\n        float _4157;\n        if (_4129 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4157 = ((-1.0) - _4109) / _4129;\n        }\n        else\n        {\n            _4157 = 1000000015047466219876688855040.0;\n        }\n        _4143 = _4157;\n    }\n    float tx = _4143;\n    float _4174;\n    if (_4133 > 9.9999999747524270787835121154785e-07)\n    {\n        _4174 = (1.0 - _4116) / _4133;\n    }\n    else\n    {\n        float _4187;\n        if (_4133 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4187 = ((-1.0) - _4116) / _4133;\n        }\n        else\n        {\n            _4187 = 1000000015047466219876688855040.0;\n        }\n        _4174 = _4187;\n    }\n    float ty = _4174;\n    float _4203;\n    if (_4137 > 9.9999999747524270787835121154785e-07)\n    {\n        _4203 = (1.0 - _4123) / _4137;\n    }\n    else\n    {\n        float _4216;\n        if (_4137 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4216 = ((-1.0) - _4123) / _4137;\n        }\n        else\n        {\n            _4216 = 1000000015047466219876688855040.0;\n        }\n        _4203 = _4216;\n    }\n    float _4228 = tx;\n    float _4231 = (_4228 > 0.0) ? _4228 : 1000000015047466219876688855040.0;\n    tx = _4231;\n    float _4232 = ty;\n    float _4235 = (_4232 > 0.0) ? _4232 : 1000000015047466219876688855040.0;\n    ty = _4235;\n    float _4245 = min(_4231, min(_4235, (_4203 > 0.0) ? _4203 : 1000000015047466219876688855040.0));\n    if (_4245 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4261 = (fa_world_pos + (d * _4245)) - posw.xyz;\n    vec3 _4266;\n    if (dot(_4261, _4261) > 1.0000000133514319600180897396058e-10)\n    {\n        _4266 = normalize(_4261);\n    }\n    else\n    {\n        _4266 = d;\n    }\n    return _4266;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4312 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4312 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4340 = rough * rough;\n            float _4371 = 0.60000002384185791015625 * _4340;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4340)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4371, 0.0500000007450580596923828125 + _4371, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4340 * 0.60000002384185791015625));\n        }\n        outc = base * _4312;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4430 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4430 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4462 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4462 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _5109;\n        if (L.aniso >= 0.0)\n        {\n            _5109 = L.b;\n        }\n        else\n        {\n            _5109 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_5109, v), _5109), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5145 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _5145.x) + (vec3(L.f90) * _5145.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _5203 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _5203.x) + _5203.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4673 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4673.x) + vec3(_4673.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _5232 = clamp(s.metallic, 0.0, 1.0);\n    float _5236 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _5243 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_5232));\n    vec3 f0 = _5243;\n    vec3 _5247 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _5247;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _5232;\n    float param_5 = _5236;\n    vec3 param_6 = _5243;\n    FaLayers _5264 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_5264.on)\n    {\n        FaLayers param_7 = _5264;\n        vec3 param_8 = _5247;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _5236;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    vec3 param_13 = _5247;\n    vec3 param_14 = i.view_dir;\n    vec3 param_15 = f0;\n    float param_16 = _5236;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5559;\n    if (fa_lm.z > 0.5)\n    {\n        _5559 = 0.0;\n    }\n    else\n    {\n        _5559 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5570 = _5559 < 1.0;\n    bool _5576;\n    if (_5570)\n    {\n        int param = li;\n        _5576 = fa_light_baked(param);\n    }\n    else\n    {\n        _5576 = _5570;\n    }\n    return _5576 ? _5559 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _695 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _708 = (c - (ru * hx)) - p;\n        vec3 _714 = ru * (2.0 * hx);\n        float _720 = max(dot(_714, _714), 9.9999999392252902907785028219223e-09);\n        float _724 = dot(_708, _714);\n        float t = clamp((-_724) / _720, 0.0, 1.0);\n        if (_695)\n        {\n            float _739 = dot(r, _714);\n            float _745 = _720 - (_739 * _739);\n            if (abs(_745) > (9.9999997473787516355514526367188e-06 * _720))\n            {\n                t = clamp(((dot(r, _708) * _739) - _724) / _745, 0.0, 1.0);\n            }\n        }\n        return (p + _708) + (_714 * t);\n    }\n    vec3 q = p;\n    float _777 = dot(r, axis);\n    bool _785;\n    if (_695)\n    {\n        _785 = abs(_777) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _785 = _695;\n    }\n    if (_785)\n    {\n        float _795 = dot(c - p, axis) / _777;\n        if (_795 > 0.0)\n        {\n            q = p + (r * _795);\n        }\n    }\n    vec3 _808 = q - c;\n    vec2 xy = vec2(dot(_808, ru), dot(_808, uu));\n    if (shape > 0.5)\n    {\n        float _823 = length(xy);\n        if (_823 > hx)\n        {\n            xy *= (hx / _823);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _615 = dot(d, right);\n    float _619 = dot(d, up);\n    float _630;\n    if (((_615 * _615) + (_619 * _619)) > 1.0000000133514319600180897396058e-10)\n    {\n        _630 = atan(_619, _615) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _630 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_630 - floor(_630)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _466 = abs(d);\n    float _468 = _466.x;\n    float _470 = _466.y;\n    bool _471 = _468 >= _470;\n    bool _479;\n    if (_471)\n    {\n        _479 = _468 >= _466.z;\n    }\n    else\n    {\n        _479 = _471;\n    }\n    int _480;\n    if (_479)\n    {\n        _480 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _494;\n        if (_470 >= _466.z)\n        {\n            _494 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _494 = (d.z > 0.0) ? 4 : 5;\n        }\n        _480 = _494;\n    }\n    return _480;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _861 = fa_light_base(param);\n    bool _865 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _861;\n    vec4 _869 = fa_light_texel(param_1);\n    int param_2 = _861 + 1;\n    vec4 _874 = fa_light_texel(param_2);\n    float _877 = _874.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _889 = _865 && (_877 > 2.5);\n    fa_light_is_area = _889;\n    bool _891 = _877 < 0.5;\n    vec3 l;\n    if (_891)\n    {\n        l = normalize(_869.xyz);\n        if (_865)\n        {\n            int param_3 = _861 + 6;\n            vec4 _905 = fa_light_texel(param_3);\n            if (_905.z > 0.5)\n            {\n                int param_4 = _861 + 4;\n                vec4 _915 = fa_light_texel(param_4);\n                int param_5 = _861 + 5;\n                vec4 _920 = fa_light_texel(param_5);\n                vec2 param_6 = _905.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _915.xyz) * _915.w, (-dot(world_pos, _920.xyz)) * _920.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _950 = _869.xyz;\n        vec3 _952 = _950 - world_pos;\n        vec3 to_light = _952;\n        float _955 = length(_952);\n        float reach = _955;\n        bool front = true;\n        if (_889)\n        {\n            int param_8 = _861 + 7;\n            reach = max(_955 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _861 + 4;\n            vec4 _979 = fa_light_texel(param_9);\n            int param_10 = _861 + 5;\n            vec4 _984 = fa_light_texel(param_10);\n            int param_11 = _861 + 6;\n            vec4 _989 = fa_light_texel(param_11);\n            float _990 = _989.w;\n            int param_12 = _861 + 2;\n            vec3 _997 = normalize(fa_light_texel(param_12).xyz);\n            bool _999 = _990 > 1.5;\n            bool _1007;\n            if (!_999)\n            {\n                _1007 = dot(_997, to_light) < 0.0;\n            }\n            else\n            {\n                _1007 = _999;\n            }\n            front = _1007;\n            vec3 r = vec3(0.0);\n            vec3 _1016 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1020 = dot(n, n) > 0.5;\n            bool _1028;\n            if (_1020)\n            {\n                _1028 = dot(_1016, _1016) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1028 = _1020;\n            }\n            if (_1028)\n            {\n                r = reflect(-normalize(_1016), normalize(n));\n            }\n            vec3 param_13 = _950;\n            vec3 param_14 = _997;\n            vec3 param_15 = _979.xyz;\n            vec3 param_16 = _984.xyz;\n            float param_17 = _979.w;\n            float param_18 = _984.w;\n            float param_19 = _990;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1064 = length(to_light);\n        dist = _1064;\n        l = to_light / vec3(max(_1064, 9.9999997473787516355514526367188e-05));\n        float _1078 = reach / max(_869.w, 0.001000000047497451305389404296875);\n        float _1084 = clamp(1.0 - (_1078 * _1078), 0.0, 1.0);\n        float _1086;\n        if (front)\n        {\n            _1086 = _1084 * _1084;\n        }\n        else\n        {\n            _1086 = 0.0;\n        }\n        atten = _1086;\n        bool _1097 = _877 < 2.5;\n        if ((_877 > 1.5) && _1097)\n        {\n            int param_22 = _861 + 2;\n            vec4 _1105 = fa_light_texel(param_22);\n            float _1115 = _1105.w;\n            int param_23 = _861 + 3;\n            vec4 _1120 = fa_light_texel(param_23);\n            float _1121 = _1120.x;\n            float cos_inner = _1121;\n            if (_1121 > 1.5)\n            {\n                cos_inner = mix(_1115, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1115, cos_inner, dot(-l, normalize(_1105.xyz)));\n        }\n        if (_865 && (_877 < 1.5))\n        {\n            int param_24 = _861 + 6;\n            vec4 _1145 = fa_light_texel(param_24);\n            if (_1145.z > 0.5)\n            {\n                vec3 _1153 = -to_light;\n                int param_25 = _861 + 4;\n                int param_26 = _861 + 5;\n                vec3 _1167 = fa_light_texel(param_25).xyz;\n                vec3 _1171 = fa_light_texel(param_26).xyz;\n                vec3 _1180 = vec3(dot(_1153, _1167), dot(_1153, _1171), dot(_1153, cross(_1167, _1171)));\n                vec3 param_27 = _1180;\n                int _1184 = fa_cube_face(param_27);\n                int param_28 = _1184;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1211 = vec2(dot(_1180, cross(param_29, param_30)), dot(_1180, param_30)) / vec2(max(dot(_1180, param_29), 9.9999997473787516355514526367188e-05));\n                int _1215 = _1184 / 3;\n                vec2 param_31 = _1145.xy + (vec2(float(_1184 - (_1215 * 3)), float(_1215)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1211.x), 0.5 - (0.5 * _1211.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _861 + 7;\n            vec4 _1245 = fa_light_texel(param_33);\n            if (_1245.z > 0.5)\n            {\n                int param_34 = _861 + 2;\n                int param_35 = _861 + 4;\n                int param_36 = _861 + 5;\n                vec2 param_37 = _1245.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_865 && _1097)\n            {\n                int param_42 = _861 + 6;\n                vec4 _1292 = fa_light_texel(param_42);\n                int param_43 = _861 + 7;\n                vec4 _1297 = fa_light_texel(param_43);\n                bool _1300 = _1292.z > 0.5;\n                bool _1307;\n                if (!_1300)\n                {\n                    _1307 = _1297.z > 0.5;\n                }\n                else\n                {\n                    _1307 = _1300;\n                }\n                if (_1307)\n                {\n                    int param_44 = _861 + 2;\n                    vec4 _1314 = fa_light_texel(param_44);\n                    vec3 _1318 = normalize(_1314.xyz);\n                    int param_45 = _861 + 4;\n                    vec4 _1323 = fa_light_texel(param_45);\n                    int param_46 = _861 + 5;\n                    vec4 _1328 = fa_light_texel(param_46);\n                    if (_1300)\n                    {\n                        vec3 _1336 = -to_light;\n                        float _1343 = _1314.w;\n                        float _1359 = 0.5 / max(dot(_1336, _1318) * (sqrt(max(1.0 - (_1343 * _1343), 0.0)) / max(_1343, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1292.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1336, _1323.xyz) * _1359), 0.5 - (dot(_1336, _1328.xyz) * _1359));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1297.z > 0.5)\n                    {\n                        vec2 param_49 = _1297.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1318;\n                        vec3 param_52 = _1323.xyz;\n                        vec3 param_53 = _1328.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _7490 = _874.xyz * atten;\n    if (_865)\n    {\n        _7490 *= fa_light_tint;\n    }\n    int _1427;\n    if (_891)\n    {\n        _1427 = 0;\n    }\n    else\n    {\n        _1427 = ((_877 > 1.5) && (_877 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _7490, atten, 1.0, dist, _1427);\n}\n\nfloat fa_rt_local_tap(ivec2 p, ivec2 size, float d, float tol, float div, inout float best)\n{\n    vec4 _3388 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(p, ivec2(0), size - ivec2(1)), 0);\n    bool _3391 = _3388.w > 0.5;\n    bool _3401;\n    if (_3391)\n    {\n        _3401 = abs(d - _3388.x) <= tol;\n    }\n    else\n    {\n        _3401 = _3391;\n    }\n    if (_3401)\n    {\n        best = min(best, mod(floor(_3388.z / div), 256.0) * 0.0039215688593685626983642578125);\n    }\n    return best;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2216 = fa_shadow_depth(param, param_1);\n    float _2220;\n    if (conv.x < 0.5)\n    {\n        _2220 = _2216;\n    }\n    else\n    {\n        _2220 = (conv.y * conv.z) / (conv.z - (_2216 * (conv.z - conv.y)));\n    }\n    return _2220;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2266 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2272 = vec2(cos(_2266), sin(_2266));\n    vec2 dir = _2272;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2281;\n        if (k < 0.0)\n        {\n            _2281 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2281 = k;\n        }\n        float _2300 = clamp((_2281 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2319 = sqrt((float(i) + 0.5) * 0.0625) * _2300;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2319));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2333 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2333 < (zr - (_2319 * plane)))\n            {\n                sum += _2333;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2361 = sum / cnt;\n        float _2371;\n        if (k < 0.0)\n        {\n            _2371 = (-k) / max(_2361, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2371 = k;\n        }\n        radius = clamp(((max(zr - _2361, 0.0) * unit) * _2371) / texel_m, 1.5, 16.0);\n        dir = _2272;\n    }\n    float lit = 0.0;\n    int _2397 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2397; i_1++)\n    {\n        float _2416 = sqrt((float(i_1) + 0.5) / float(_2397)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2416));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2416 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2397);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2621 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2628;\n    if (!_2621)\n    {\n        _2628 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2628 = _2621;\n    }\n    if (_2628)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2641 = fa_light_texel(param);\n    float _2642 = _2641.x;\n    if (_2642 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2651 = int(_2642 + 0.5);\n    int param_1 = _2651;\n    vec4 _2655 = fa_light_texel(param_1);\n    int param_2 = _2651 + 1;\n    vec4 _2660 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2663 = _2655.y;\n    if (_2663 > 0.0)\n    {\n        float _2680 = 1.0 - smoothstep(0.75 * _2663, _2663, length(world - fa_shadows[27].xyz));\n        fade = _2680;\n        if (_2680 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2655.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2704 = (_2651 + 2) + (face * 6);\n    int param_4 = _2704;\n    int param_5 = _2704 + 1;\n    int param_6 = _2704 + 3;\n    vec4 _2718 = fa_light_texel(param_6);\n    int param_7 = _2704 + 4;\n    vec4 _2723 = fa_light_texel(param_7);\n    int param_8 = _2704 + 5;\n    vec4 _2728 = fa_light_texel(param_8);\n    float _2740 = _2728.x * max(dot(_2718, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2745 = clamp(dot(n, l), 0.0, 1.0);\n    float _2768 = clamp(dot(n, _2718.xyz), -1.0, 1.0);\n    float _2787 = min(sqrt(1.0 - (_2768 * _2768)) / max(abs(dot(n, world - lpos)) / max(dot(_2718, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2790 = _2660.y;\n    float _2792;\n    if (_2790 > 0.0)\n    {\n        _2792 = _2790;\n    }\n    else\n    {\n        _2792 = 1.5 * _2740;\n    }\n    vec4 _2812 = vec4(world + (n * (_2792 * sqrt(1.0 - (_2745 * _2745)))), 1.0);\n    float _2816 = dot(_2718, _2812);\n    float _2819 = _2728.y;\n    if (_2816 < _2819)\n    {\n        return 1.0;\n    }\n    vec2 _2834 = vec2(dot(fa_light_texel(param_4), _2812), dot(fa_light_texel(param_5), _2812)) / vec2(_2816);\n    float _2836 = _2834.x;\n    bool _2839 = _2836 < _2723.x;\n    bool _2848;\n    if (!_2839)\n    {\n        _2848 = _2836 > _2723.z;\n    }\n    else\n    {\n        _2848 = _2839;\n    }\n    bool _2857;\n    if (!_2848)\n    {\n        _2857 = _2834.y < _2723.y;\n    }\n    else\n    {\n        _2857 = _2848;\n    }\n    bool _2866;\n    if (!_2857)\n    {\n        _2866 = _2834.y > _2723.w;\n    }\n    else\n    {\n        _2866 = _2857;\n    }\n    if (_2866)\n    {\n        return 1.0;\n    }\n    float _2872 = _2660.x;\n    float _2874;\n    if (_2872 > 0.0)\n    {\n        _2874 = _2872;\n    }\n    else\n    {\n        _2874 = 1.5 * _2740;\n    }\n    vec2 param_9 = _2834;\n    vec4 param_10 = _2723;\n    float param_11 = _2816 - (_2874 * (1.0 + (0.5 * _2787)));\n    float param_12 = _2740;\n    float param_13 = 1.0;\n    float param_14 = _2728.z * 0.25;\n    float param_15 = (_2740 * min(_2787, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2819, _2728.z);\n    int param_17 = int(_2655.z + 0.5);\n    float param_18 = _2655.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3419 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3425;\n    if (_3419)\n    {\n        _3425 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3425 = _3419;\n    }\n    bool _3431;\n    if (_3425)\n    {\n        _3431 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3431 = _3425;\n    }\n    if (_3431)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3443 = fa_light_texel(param);\n        float _3444 = _3443.z;\n        if (_3444 > 0.5)\n        {\n            float _3457 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3463 = ((0.00200000009499490261077880859375 * _3457) + 0.00999999977648258209228515625) + fa_rt_slope;\n            vec4 _3469 = vec4(world, 1.0);\n            float _3474 = dot(fa_mesh_fs_params[28], _3469);\n            if (_3474 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3491 = vec2(dot(fa_mesh_fs_params[26], _3469), dot(fa_mesh_fs_params[27], _3469)) / vec2(_3474);\n                float _3496 = (_3491.x * 0.5) + 0.5;\n                float _3500;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3500 = (_3491.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3500 = 0.5 - (_3491.y * 0.5);\n                }\n                bool _3516 = _3496 >= 0.0;\n                bool _3522;\n                if (_3516)\n                {\n                    _3522 = _3496 < 1.0;\n                }\n                else\n                {\n                    _3522 = _3516;\n                }\n                bool _3528;\n                if (_3522)\n                {\n                    _3528 = _3500 >= 0.0;\n                }\n                else\n                {\n                    _3528 = _3522;\n                }\n                bool _3534;\n                if (_3528)\n                {\n                    _3534 = _3500 < 1.0;\n                }\n                else\n                {\n                    _3534 = _3528;\n                }\n                if (_3534)\n                {\n                    ivec2 _3541 = ivec2(fa_mesh_fs_params[24].zw);\n                    ivec2 _3552 = clamp(ivec2(vec2(_3496, _3500) * fa_mesh_fs_params[24].zw), ivec2(0), _3541 - ivec2(1));\n                    float _3556;\n                    if (_3444 < 1.5)\n                    {\n                        _3556 = 1.0;\n                    }\n                    else\n                    {\n                        _3556 = (_3444 < 2.5) ? 256.0 : 65536.0;\n                    }\n                    float best = 2.0;\n                    vec4 _3572 = texelFetch(fa_screen_tex_fa_shadow_smp, _3552, 0);\n                    bool _3575 = _3572.w > 0.5;\n                    bool _3585;\n                    if (_3575)\n                    {\n                        _3585 = abs(_3457 - _3572.x) <= _3463;\n                    }\n                    else\n                    {\n                        _3585 = _3575;\n                    }\n                    if (_3585)\n                    {\n                        best = mod(floor(_3572.z / _3556), 256.0) * 0.0039215688593685626983642578125;\n                    }\n                    else\n                    {\n                        ivec2 param_1 = _3552 + ivec2(-1);\n                        ivec2 param_2 = _3541;\n                        float param_3 = _3457;\n                        float param_4 = _3463;\n                        float param_5 = _3556;\n                        float param_6 = best;\n                        float _3611 = fa_rt_local_tap(param_1, param_2, param_3, param_4, param_5, param_6);\n                        best = _3611;\n                        ivec2 param_7 = _3552 + ivec2(0, -1);\n                        ivec2 param_8 = _3541;\n                        float param_9 = _3457;\n                        float param_10 = _3463;\n                        float param_11 = _3556;\n                        float param_12 = _3611;\n                        float _3626 = fa_rt_local_tap(param_7, param_8, param_9, param_10, param_11, param_12);\n                        best = _3626;\n                        ivec2 param_13 = _3552 + ivec2(1, -1);\n                        ivec2 param_14 = _3541;\n                        float param_15 = _3457;\n                        float param_16 = _3463;\n                        float param_17 = _3556;\n                        float param_18 = _3626;\n                        float _3641 = fa_rt_local_tap(param_13, param_14, param_15, param_16, param_17, param_18);\n                        best = _3641;\n                        ivec2 param_19 = _3552 + ivec2(-1, 0);\n                        ivec2 param_20 = _3541;\n                        float param_21 = _3457;\n                        float param_22 = _3463;\n                        float param_23 = _3556;\n                        float param_24 = _3641;\n                        float _3656 = fa_rt_local_tap(param_19, param_20, param_21, param_22, param_23, param_24);\n                        best = _3656;\n                        ivec2 param_25 = _3552 + ivec2(1, 0);\n                        ivec2 param_26 = _3541;\n                        float param_27 = _3457;\n                        float param_28 = _3463;\n                        float param_29 = _3556;\n                        float param_30 = _3656;\n                        float _3671 = fa_rt_local_tap(param_25, param_26, param_27, param_28, param_29, param_30);\n                        best = _3671;\n                        ivec2 param_31 = _3552 + ivec2(-1, 1);\n                        ivec2 param_32 = _3541;\n                        float param_33 = _3457;\n                        float param_34 = _3463;\n                        float param_35 = _3556;\n                        float param_36 = _3671;\n                        float _3686 = fa_rt_local_tap(param_31, param_32, param_33, param_34, param_35, param_36);\n                        best = _3686;\n                        ivec2 param_37 = _3552 + ivec2(0, 1);\n                        ivec2 param_38 = _3541;\n                        float param_39 = _3457;\n                        float param_40 = _3463;\n                        float param_41 = _3556;\n                        float param_42 = _3686;\n                        float _3701 = fa_rt_local_tap(param_37, param_38, param_39, param_40, param_41, param_42);\n                        best = _3701;\n                        ivec2 param_43 = _3552 + ivec2(1);\n                        ivec2 param_44 = _3541;\n                        float param_45 = _3457;\n                        float param_46 = _3463;\n                        float param_47 = _3556;\n                        float param_48 = _3701;\n                        float _3716 = fa_rt_local_tap(param_43, param_44, param_45, param_46, param_47, param_48);\n                        best = _3716;\n                    }\n                    if (best <= 1.0)\n                    {\n                        float _3724;\n                        if (fa_mesh_fs_params[25].z > 0.5)\n                        {\n                            int param_49 = li;\n                            vec3 param_50 = lpos;\n                            vec3 param_51 = world;\n                            vec3 param_52 = n;\n                            vec3 param_53 = l;\n                            _3724 = min(best, fa_shadow_local(param_49, param_50, param_51, param_52, param_53));\n                        }\n                        else\n                        {\n                            _3724 = best;\n                        }\n                        return _3724;\n                    }\n                }\n            }\n            float _3747;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_54 = li;\n                vec3 param_55 = lpos;\n                vec3 param_56 = world;\n                vec3 param_57 = n;\n                vec3 param_58 = l;\n                _3747 = fa_shadow_local(param_54, param_55, param_56, param_57, param_58);\n            }\n            else\n            {\n                _3747 = 1.0;\n            }\n            return _3747;\n        }\n    }\n    int param_59 = li;\n    vec3 param_60 = lpos;\n    vec3 param_61 = world;\n    vec3 param_62 = n;\n    vec3 param_63 = l;\n    return fa_shadow_local(param_59, param_60, param_61, param_62, param_63);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2159;\n    if (i == 0)\n    {\n        _2159 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2175;\n        if (i == 1)\n        {\n            _2175 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2183;\n            if (i == 2)\n            {\n                _2183 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2183 = fa_shadows[24].w;\n            }\n            _2175 = _2183;\n        }\n        _2159 = _2175;\n    }\n    return _2159;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2462 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2467 = clamp(dot(n, l), 0.0, 1.0);\n    float _2473 = sqrt(1.0 - (_2467 * _2467));\n    float _2481 = min(_2473 / max(_2467, 0.20000000298023223876953125), 4.0);\n    float _2486;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2486 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2486 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2511 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2486 * _2473)), 1.0);\n    float _2518 = _2511.x;\n    bool _2521 = _2518 < fa_shadows[ci * 1 + 16].x;\n    bool _2530;\n    if (!_2521)\n    {\n        _2530 = _2518 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2530 = _2521;\n    }\n    bool _2539;\n    if (!_2530)\n    {\n        _2539 = _2511.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2539 = _2530;\n    }\n    bool _2548;\n    if (!_2539)\n    {\n        _2548 = _2511.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2548 = _2539;\n    }\n    bool _2555;\n    if (!_2548)\n    {\n        _2555 = _2511.z > 1.0;\n    }\n    else\n    {\n        _2555 = _2548;\n    }\n    if (_2555)\n    {\n        return -1.0;\n    }\n    float _2563;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2563 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2563 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2511.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2511.z - ((_2563 * (1.0 + (0.5 * _2481))) / _2462);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2462;\n    float param_5 = _2462 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2481, 3.0)) * 0.5) / _2462;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2941 = int(fa_shadows[25].x + 0.5);\n    if (_2941 < 1)\n    {\n        return 1.0;\n    }\n    float _2956 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2941 - 1;\n    if (_2956 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2968 = _2941 > 1;\n    bool _2975;\n    if (_2968)\n    {\n        _2975 = _2956 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2975 = _2968;\n    }\n    if (_2975)\n    {\n        ci = 1;\n    }\n    bool _2979 = _2941 > 2;\n    bool _2986;\n    if (_2979)\n    {\n        _2986 = _2956 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2986 = _2979;\n    }\n    if (_2986)\n    {\n        ci = 2;\n    }\n    bool _2990 = _2941 > 3;\n    bool _2997;\n    if (_2990)\n    {\n        _2997 = _2956 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2997 = _2990;\n    }\n    if (_2997)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3008 = min(_2941, 4);\n    float _3049;\n    for (int c = ci; c < _3008; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3028 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3028;\n            break;\n        }\n        if (_3028 < 0.0)\n        {\n            continue;\n        }\n        s = _3028;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3049 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3049 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3068 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3049, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2956 - (fa_shadow_split_at(param_7) - _3068)) / _3068, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3100;\n        if ((ci + 1) < _2941)\n        {\n            _3100 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3100 = 1.0;\n        }\n        s = mix(s, _3100, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3205 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3211;\n    if (_3205)\n    {\n        _3211 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3211 = _3205;\n    }\n    if (_3211)\n    {\n        float _3225 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        vec4 _3233 = vec4(fa_world_pos, 1.0);\n        float _3239 = dot(fa_mesh_fs_params[28], _3233);\n        if (_3239 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3258 = vec2(dot(fa_mesh_fs_params[26], _3233), dot(fa_mesh_fs_params[27], _3233)) / vec2(_3239);\n            float _3263 = (_3258.x * 0.5) + 0.5;\n            float _3267;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3267 = (_3258.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3267 = 0.5 - (_3258.y * 0.5);\n            }\n            bool _3283 = _3263 >= 0.0;\n            bool _3289;\n            if (_3283)\n            {\n                _3289 = _3263 < 1.0;\n            }\n            else\n            {\n                _3289 = _3283;\n            }\n            bool _3295;\n            if (_3289)\n            {\n                _3295 = _3267 >= 0.0;\n            }\n            else\n            {\n                _3295 = _3289;\n            }\n            bool _3301;\n            if (_3295)\n            {\n                _3301 = _3267 < 1.0;\n            }\n            else\n            {\n                _3301 = _3295;\n            }\n            if (_3301)\n            {\n                vec4 _3326 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3263, _3267) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3329 = _3326.w > 0.5;\n                bool _3345;\n                if (_3329)\n                {\n                    _3345 = abs(_3225 - _3326.x) <= (((0.00200000009499490261077880859375 * _3225) + 0.00999999977648258209228515625) + fa_rt_slope);\n                }\n                else\n                {\n                    _3345 = _3329;\n                }\n                if (_3345)\n                {\n                    float _3351;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3351 = min(_3326.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3351 = _3326.y;\n                    }\n                    return _3351;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5303 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5310;\n    if (!_5303)\n    {\n        _5310 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5310 = _5303;\n    }\n    if (_5310)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5323 = fa_light_texel(param);\n    float _5324 = _5323.y;\n    float len = _5324;\n    if (_5324 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5336 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5345 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5336);\n    if (_5345 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5351 = len;\n    float _5354 = min(_5351, 0.89999997615814208984375 * dist);\n    len = _5354;\n    float _5359 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5336);\n    float _5364 = _5359 + (0.5 * _5354);\n    vec3 _5370 = world + (gn * _5359);\n    float _5372 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5433;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5387 = (float(k) + _5372) * 0.083333335816860198974609375;\n        vec3 _5395 = _5370 + (l * (_5387 * len));\n        vec4 _5401 = vec4(_5395, 1.0);\n        float _5406 = dot(fa_mesh_fs_params[28], _5401);\n        if (_5406 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5424 = vec2(dot(fa_mesh_fs_params[26], _5401), dot(fa_mesh_fs_params[27], _5401)) / vec2(_5406);\n        float _5428 = _5424.x * 0.5;\n        float _5429 = _5428 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5433 = (_5424.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5433 = 0.5 - (_5424.y * 0.5);\n        }\n        bool _5449 = _5429 < 0.0;\n        bool _5456;\n        if (!_5449)\n        {\n            _5456 = _5429 >= 1.0;\n        }\n        else\n        {\n            _5456 = _5449;\n        }\n        bool _5463;\n        if (!_5456)\n        {\n            _5463 = _5433 < 0.0;\n        }\n        else\n        {\n            _5463 = _5456;\n        }\n        bool _5470;\n        if (!_5463)\n        {\n            _5470 = _5433 >= 1.0;\n        }\n        else\n        {\n            _5470 = _5463;\n        }\n        if (_5470)\n        {\n            break;\n        }\n        vec4 _5494 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5429, _5433) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5494.w < 0.5)\n        {\n            continue;\n        }\n        float _5512 = (dot(fa_mesh_fs_params[29].xyz, _5395) + fa_mesh_fs_params[29].w) - _5494.x;\n        if ((_5512 > _5359) && (_5512 < _5364))\n        {\n            occ = max(occ, (1.0 - (_5387 * _5387)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5429, 0.5 - _5428), min(_5433, 1.0 - _5433))));\n        }\n    }\n    return 1.0 - (occ * _5345);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5644 = fa_baked_keep(param);\n    if (_5644 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5670 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _7623 = _5670.color;\n    float _7624 = _5670.attenuation;\n    float _7625 = _5670.shadow;\n    bool _5673 = _5670.type == 0;\n    if (_5673 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5670.direction;\n        float _5684 = fa_shadow_factor(param_5, param_6);\n        _7625 = _5684;\n        _7623 *= _5684;\n    }\n    else\n    {\n        bool _5695 = _5670.type != 0;\n        bool _5701;\n        if (_5695)\n        {\n            _5701 = _7624 > 0.0;\n        }\n        else\n        {\n            _5701 = _5695;\n        }\n        if (_5701)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5670.direction;\n            float _5720 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _7625 = _5720;\n            _7623 *= _5720;\n        }\n    }\n    bool _5730 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5736;\n    if (_5730)\n    {\n        _5736 = _7624 > 0.0;\n    }\n    else\n    {\n        _5736 = _5730;\n    }\n    if (_5736)\n    {\n        float _5743;\n        if (_5673)\n        {\n            _5743 = 1000000000.0;\n        }\n        else\n        {\n            _5743 = _5670._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5670.direction;\n        float param_18 = _5743;\n        float _5761 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7625 *= _5761;\n        _7623 *= _5761;\n    }\n    float _5774 = _7624;\n    float _5775 = _5774 * _5644;\n    _7624 = _5775;\n    vec3 _5779 = _7623;\n    vec3 _5780 = _5779 * _5644;\n    _7623 = _5780;\n    return LightSample(_5670.direction, _5780, _5775, _7625, _5670._distance, _5670.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3128 = int(fa_shadows[25].x + 0.5);\n    float _3138 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3143 = _3128 > 0;\n    bool _3152;\n    if (_3143)\n    {\n        int param = _3128 - 1;\n        _3152 = _3138 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3152 = _3143;\n    }\n    if (_3152)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3158 = _3128 > 1;\n        bool _3165;\n        if (_3158)\n        {\n            _3165 = _3138 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3165 = _3158;\n        }\n        if (_3165)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3171 = _3128 > 2;\n        bool _3178;\n        if (_3171)\n        {\n            _3178 = _3138 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3178 = _3171;\n        }\n        if (_3178)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3184 = _3128 > 3;\n        bool _3191;\n        if (_3184)\n        {\n            _3191 = _3138 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3191 = _3184;\n        }\n        if (_3191)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_rt_slope = 0.0;\n    fa_inst_load();\n    vec3 _7308 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _7308 = -_7308;\n    }\n    vec3 _6931 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _7308, fa_world_tangent, fa_uv, fa_vertex_color, _6931, gl_FrontFacing);\n    Surface _6939 = fa_standard_surface(param_1);\n    vec3 _7347 = _6939.albedo;\n    float _7348 = _6939.alpha;\n    vec3 _7349 = _6939.normal;\n    float _7350 = _6939.metallic;\n    float _7351 = _6939.roughness;\n    float _7352 = _6939.occlusion;\n    vec3 _7353 = _6939.emission;\n    float _7354 = _6939.clearcoat;\n    float _7355 = _6939.clearcoat_roughness;\n    vec3 _7356 = _6939.sheen_color;\n    float _7357 = _6939.sheen_roughness;\n    float _7358 = _6939.anisotropy;\n    float _7359 = _6939.anisotropy_rotation;\n    float _7360 = _6939.specular;\n    float _7361 = _6939.ior;\n    vec3 _7362 = _6939.specular_color;\n    float _7363 = _6939.transmission;\n    float _7364 = _6939.thickness;\n    vec3 _7365 = _6939.attenuation_color;\n    float _7366 = _6939.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _7308, fa_world_tangent, fa_uv, fa_vertex_color, _6931, gl_FrontFacing);\n    Surface param_3 = _6939;\n    surface(param_2, param_3);\n    _7347 = param_3.albedo;\n    _7348 = param_3.alpha;\n    _7349 = param_3.normal;\n    _7350 = param_3.metallic;\n    _7351 = param_3.roughness;\n    _7352 = param_3.occlusion;\n    _7353 = param_3.emission;\n    _7354 = param_3.clearcoat;\n    _7355 = param_3.clearcoat_roughness;\n    _7356 = param_3.sheen_color;\n    _7357 = param_3.sheen_roughness;\n    _7358 = param_3.anisotropy;\n    _7359 = param_3.anisotropy_rotation;\n    _7360 = param_3.specular;\n    _7361 = param_3.ior;\n    _7362 = param_3.specular_color;\n    _7363 = param_3.transmission;\n    _7364 = param_3.thickness;\n    _7365 = param_3.attenuation_color;\n    _7366 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _7308;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _7347 = param_6;\n    _7349 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _7347;\n    }\n    else\n    {\n        vec3 _6978 = _7349;\n        vec3 _6979 = normalize(_6978);\n        _7349 = _6979;\n        vec3 param_8 = _6979;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _7308, fa_world_tangent, fa_uv, fa_vertex_color, _6931, gl_FrontFacing);\n        Surface param_10 = Surface(_7347, _7348, _7349, _7350, _7351, _7352, _7353, _7354, _7355, _7356, _7357, _7358, _7359, _7360, _7361, _7362, _7363, _7364, _7365, _7366);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _6998 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6998; ln++)\n        {\n            int param_12 = ln;\n            int _7011 = fa_cl_light(param_12);\n            int param_13 = _7011;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _7011;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _7308;\n            LightSample _7027 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _7308, fa_world_tangent, fa_uv, fa_vertex_color, _6931, gl_FrontFacing);\n            Surface param_18 = Surface(_7347, _7348, _7349, _7350, _7351, _7352, _7353, _7354, _7355, _7356, _7357, _7358, _7359, _7360, _7361, _7362, _7363, _7364, _7365, _7366);\n            LightSample param_19 = _7027;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _7042 = result;\n    vec3 _7043 = _7042 + _7353;\n    result = _7043;\n    vec3 param_20 = _7043;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _7052 = fa_mesh_fs_params[7].w > 0.0;\n    bool _7059;\n    if (!_7052)\n    {\n        _7059 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _7059 = _7052;\n    }\n    if (_7059)\n    {\n        vec3 _7068 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _7074 = dot(_7068, fa_mesh_fs_params[9].xyz);\n        bool _7078 = fa_mesh_fs_params[9].w > 0.5;\n        float _7079;\n        if (_7078)\n        {\n            _7079 = _7074;\n        }\n        else\n        {\n            _7079 = length(_7068);\n        }\n        float _7091 = _7079 - fa_mesh_fs_params[8].x;\n        if (_7091 > 0.0)\n        {\n            float _7100 = fa_mesh_fs_params[7].w * _7091;\n            float tau = _7100 * _7100;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _7116;\n                if (_7078)\n                {\n                    _7116 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _7074);\n                }\n                else\n                {\n                    _7116 = fa_mesh_fs_params[0].y;\n                }\n                float _7137 = mix(_7116, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _7079, 0.0, 1.0));\n                float _7141 = fa_world_pos.y - _7137;\n                float _7146 = _7137 - fa_mesh_fs_params[8].z;\n                float _7151 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _7154 = _7146 <= 0.0;\n                bool _7155 = !_7154;\n                bool _7161;\n                if (_7155)\n                {\n                    _7161 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7161 = _7154;\n                }\n                float _7162;\n                if (_7161)\n                {\n                    _7162 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _7162 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _7146, 80.0));\n                }\n                bool _7189;\n                if (_7155)\n                {\n                    _7189 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7189 = _7154;\n                }\n                float _7190;\n                if (_7189)\n                {\n                    _7190 = fa_mesh_fs_params[8].y * _7146;\n                }\n                else\n                {\n                    _7190 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7146, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _7215 = _7151 <= 0.0;\n                bool _7222;\n                if (!_7215)\n                {\n                    _7222 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7222 = _7215;\n                }\n                float _7223;\n                if (_7222)\n                {\n                    _7223 = fa_mesh_fs_params[8].y * _7151;\n                }\n                else\n                {\n                    _7223 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7151, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _7250;\n                if (abs(_7141) < 0.001000000047497451305389404296875)\n                {\n                    _7250 = _7162;\n                }\n                else\n                {\n                    _7250 = (_7223 - _7190) / _7141;\n                }\n                tau += (_7091 * max(_7250, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _7348);\n}\n\n",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_517",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
            "inst_name": "_2169",
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
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_388, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4774[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat fa_rt_slope;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1445 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1452;\n    if (!_1445)\n    {\n        _1452 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1452 = _1445;\n    }\n    bool _1460;\n    if (!_1452)\n    {\n        _1460 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1460 = _1452;\n    }\n    bool _1467;\n    if (!_1460)\n    {\n        _1467 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1467 = _1460;\n    }\n    bool _1474;\n    if (!_1467)\n    {\n        _1474 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1474 = _1467;\n    }\n    if (_1474)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1484 = vec4(world_pos, 1.0);\n    float _1490 = dot(fa_mesh_fs_params[16], _1484);\n    if (!(_1490 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1512 = vec2(dot(fa_mesh_fs_params[14], _1484), dot(fa_mesh_fs_params[15], _1484)) / vec2(_1490);\n    int _1516 = int(fa_mesh_fs_params[18].x);\n    int _1520 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1520) + clamp(int(floor(((_1512.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1520 - 1)) * _1516)) + clamp(int(floor(((_1512.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1516 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1596 = fa_cluster_texel(param);\n    return ivec2(int(_1596.x), int(_1596.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    float _5589 = dot(fa_mesh_fs_params[29].xyz, world_pos) + fa_mesh_fs_params[29].w;\n    float _5592 = fwidth(_5589);\n    bool _5595 = fa_mesh_fs_params[25].y > 0.5;\n    bool _5602;\n    if (!_5595)\n    {\n        _5602 = fa_mesh_fs_params[25].w > 0.5;\n    }\n    else\n    {\n        _5602 = _5595;\n    }\n    if (_5602)\n    {\n        fa_rt_slope = min(1.5 * _5592, 0.100000001490116119384765625 * _5589);\n    }\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5618 = fa_cluster_lookup(param);\n    fa_cl_slot = _5618.x;\n    fa_cl_local = _5618.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5830 = fa_linear_to_srgb(param);\n        c = _5830;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5838 = fa_srgb_to_linear(param_1);\n            c = _5838;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _400;\n    if (i.front_facing)\n    {\n        _400 = i.world_normal;\n    }\n    else\n    {\n        _400 = -i.world_normal;\n    }\n    vec3 _424 = normalize(i.world_tangent.xyz - (_400 * dot(_400, i.world_tangent.xyz)));\n    vec3 _451 = normalize(((_424 * m.x) + ((cross(_400, _424) * i.world_tangent.w) * m.y)) + (_400 * m.z));\n    vec3 _454;\n    if (i.front_facing)\n    {\n        _454 = _451;\n    }\n    else\n    {\n        _454 = -_451;\n    }\n    return _454;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5870 = fa_tex_fix(param_2, param_3);\n    vec4 _7861 = base_t;\n    _7861.x = _5870.x;\n    _7861.y = _5870.y;\n    _7861.z = _5870.z;\n    base_t = _7861;\n    vec4 _5884 = (_7861 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _7643 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5918 = fa_tex_fix(param_6, param_7);\n        vec3 _5921 = (_5918 * 2.0) - vec3(1.0);\n        vec2 _5926 = _5921.xy * fa_mesh_fs_params[6].x;\n        vec3 _7869 = _5921;\n        _7869.x = _5926.x;\n        _7869.y = _5926.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7869;\n        _7643 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5956 = fa_tex_fix(param_12, param_13);\n    vec4 _7872 = mrt;\n    _7872.x = _5956.x;\n    _7872.y = _5956.y;\n    _7872.z = _5956.z;\n    mrt = _7872;\n    vec4 _5986 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5986.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5997 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _6029 = fa_tex_fix(param_20, param_21);\n    float _7648 = fa_mesh_fs_params[20].x;\n    float _7649 = fa_mesh_fs_params[20].y;\n    float _7652 = fa_mesh_fs_params[20].z;\n    float _7651 = fa_mesh_fs_params[21].w;\n    float _7654 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _7648 *= _5997.y;\n            _7649 *= _5997.z;\n            _7651 *= _5986.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _7652 *= mrt.x;\n            _7654 *= mrt.w;\n        }\n    }\n    return Surface(_5884.xyz, _5884.w, _7643, clamp(fa_mesh_fs_params[5].x * _5956.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5956.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5997.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _6029), _7648, _7649, fa_mesh_fs_params[21].xyz, _7651, _7652, fa_mesh_fs_params[20].w, _7654, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1676 = rect.zw - rect.xy;\n    vec2 _1680 = _1676 * atlas;\n    vec2 _1684 = ddx * _1680;\n    vec2 _1688 = ddy * _1680;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1676), clamp(0.5 * log2(max(max(dot(_1684, _1684), dot(_1688, _1688)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1721 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1728;\n    if (!_1721)\n    {\n        _1728 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1728 = _1721;\n    }\n    if (_1728)\n    {\n        return;\n    }\n    vec3 _1734 = dFdx(world_pos);\n    vec3 _1737 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1741 = fa_cluster_texel(param);\n    int _1745 = int(_1741.w);\n    if (_1745 < 1)\n    {\n        return;\n    }\n    int _1755 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1755;\n    vec4 _1759 = fa_light_texel(param_1);\n    vec2 _1762 = _1759.yz;\n    int _1766 = int(_1759.w);\n    int param_2 = _1755 + 1;\n    vec4 _1771 = fa_light_texel(param_2);\n    float _1772 = _1771.x;\n    int _1778 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1782 = int(_1741.z);\n    vec3 _2047;\n    for (int k = 0; k < _1745; k++)\n    {\n        int _1795 = _1782 + k;\n        int param_3 = _1766 + (_1795 >> 2);\n        int _1812 = (_1755 + 2) + (int(fa_light_texel(param_3)[_1795 & 3]) * 7);\n        int param_4 = _1812 + 6;\n        vec4 _1817 = fa_light_texel(param_4);\n        if (((int(_1817.w + 0.5) >> _1778) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1812;\n        vec4 _1832 = fa_light_texel(param_5);\n        int param_6 = _1812 + 1;\n        vec4 _1837 = fa_light_texel(param_6);\n        int param_7 = _1812 + 2;\n        vec4 _1842 = fa_light_texel(param_7);\n        vec3 _1845 = _1832.xyz;\n        float _1850 = dot(_1845, world_pos) + _1832.w;\n        vec3 _1852 = _1837.xyz;\n        float _1857 = dot(_1852, world_pos) + _1837.w;\n        vec3 _1859 = _1842.xyz;\n        float _1864 = dot(_1859, world_pos) + _1842.w;\n        bool _1869 = abs(_1850) > 0.5;\n        bool _1877;\n        if (!_1869)\n        {\n            _1877 = abs(_1857) > 0.5;\n        }\n        else\n        {\n            _1877 = _1869;\n        }\n        bool _1885;\n        if (!_1877)\n        {\n            _1885 = abs(_1864) > 0.5;\n        }\n        else\n        {\n            _1885 = _1877;\n        }\n        if (_1885)\n        {\n            continue;\n        }\n        float _1900 = clamp(dot(geo_normal, normalize(_1859)) * _1817.z, 0.0, 1.0);\n        if (_1900 <= 0.0)\n        {\n            continue;\n        }\n        float _1920 = (clamp((0.5 - abs(_1864)) * 10.0, 0.0, 1.0) * _1900) * _1817.x;\n        vec2 _1928 = vec2(_1850 + 0.5, 0.5 - _1857);\n        vec2 _1938 = vec2(dot(_1845, _1734), dot(_1852, _1734));\n        vec2 _1948 = vec2(dot(_1845, _1737), dot(_1852, _1737));\n        int param_8 = _1812 + 5;\n        vec4 _1953 = fa_light_texel(param_8);\n        int param_9 = _1812 + 3;\n        vec4 _1958 = fa_light_texel(param_9);\n        int param_10 = _1812 + 4;\n        vec4 _1963 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1953.xyz;\n        bool _1973 = _1958.z > _1958.x;\n        if (_1973)\n        {\n            vec4 param_11 = _1958;\n            vec2 param_12 = _1928;\n            vec2 param_13 = _1762;\n            vec2 param_14 = _1938;\n            vec2 param_15 = _1948;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1772 > 0.5) && (_1772 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1999 = fa_dc_to_linear(param_16);\n                vec4 _7731 = tx;\n                _7731.x = _1999.x;\n                _7731.y = _1999.y;\n                _7731.z = _1999.z;\n                tx = _7731;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1920 * tex_a) * _1953.w, 0.0, 1.0)));\n        if (_1963.z > _1963.x)\n        {\n            vec4 param_17 = _1963;\n            vec2 param_18 = _1928;\n            vec2 param_19 = _1762;\n            vec2 param_20 = _1938;\n            vec2 param_21 = _1948;\n            vec4 _2043 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1772 > 1.5)\n            {\n                vec3 param_22 = _2043.xyz;\n                vec3 _2053 = fa_dc_to_srgb(param_22);\n                _2047 = _2053;\n            }\n            else\n            {\n                _2047 = _2043.xyz;\n            }\n            vec3 _2062 = (_2047 * 2.0) - vec3(1.0);\n            vec2 _2067 = _2062.xy * _1817.y;\n            vec3 _2089 = (normalize(_1845) * _2067.x) + (normalize(_1852) * _2067.y);\n            vec3 _2092 = normalize(normal);\n            normal = normalize(mix(_2092, normalize((_2092 * max(_2062.z, 0.0500000007450580596923828125)) + (_2089 - (_2092 * dot(_2092, _2089)))), vec3(clamp(_1920 * (_1973 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3869 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3869;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4480 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4485 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4480 > 0.0005000000237487256526947021484375)\n    {\n        if (_4485)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4480;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4480;\n        }\n    }\n    bool _4536 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4536)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4567 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4567)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4485 || _4536) || _4567)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3889 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3892 = _3889.x;\n    float _3894 = _3889.z;\n    vec2 e = vec2(_3892, _3894);\n    if (_3889.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3894)) * ((_3892 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3892)) * ((_3894 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _6141 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _6146 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _6151 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _6156 = fa_light_texel(param_3);\n    bool _6159 = _6156.z < 0.5;\n    bool _6167;\n    if (!_6159)\n    {\n        _6167 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _6167 = _6159;\n    }\n    if (_6167)\n    {\n        return vec3(0.0);\n    }\n    float _6174 = max(_6141.w, 9.9999997473787516355514526367188e-05);\n    vec3 _6177 = _6146.xyz;\n    vec3 _6181 = _6141.xyz;\n    vec3 _6185 = (fa_world_pos - _6181) / vec3(_6174);\n    vec3 _6194 = min(_6185 + vec3(0.5), (_6177 - vec3(0.5)) - _6185);\n    float _6203 = min(_6194.x, min(_6194.y, _6194.z));\n    if (!(_6203 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6218 = _6177 - vec3(1.0);\n    vec3 _6219 = clamp(_6185, vec3(0.0), _6218);\n    vec3 _6227 = min(floor(_6219), max(_6177 - vec3(2.0), vec3(0.0)));\n    vec3 _6231 = _6219 - _6227;\n    vec3 _6242 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _6174));\n    int _6247 = int(_6151.y + 0.5);\n    float _6252 = 0.3257350027561187744140625 * n.y;\n    float _6256 = 0.3257350027561187744140625 * n.z;\n    float _6260 = 0.3257350027561187744140625 * n.x;\n    float _6267 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _6274 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _6283 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _6290 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _6303 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _6310 = 8 + int(_6156.w);\n    float _6337;\n    float _6350;\n    float _6364;\n    for (int k = 0; k < _6310; k++)\n    {\n        float _6323 = float(k & 1);\n        float _6327 = float((k >> 1) & 1);\n        float _6331 = float((k >> 2) & 1);\n        if (_6323 > 0.5)\n        {\n            _6337 = _6231.x;\n        }\n        else\n        {\n            _6337 = 1.0 - _6231.x;\n        }\n        if (_6327 > 0.5)\n        {\n            _6350 = _6231.y;\n        }\n        else\n        {\n            _6350 = 1.0 - _6231.y;\n        }\n        if (_6331 > 0.5)\n        {\n            _6364 = _6231.z;\n        }\n        else\n        {\n            _6364 = 1.0 - _6231.z;\n        }\n        float _6374 = (_6337 * _6350) * _6364;\n        if (!(_6374 > 0.0))\n        {\n            continue;\n        }\n        vec3 _6387 = min(_6227 + vec3(_6323, _6327, _6331), _6218);\n        int _6407 = int(((_6151.x + _6387.x) + (_6146.x * (_6387.y + (_6146.y * _6387.z)))) + 0.5);\n        vec2 _6422 = vec2(float(_6407 % _6247) * 10.0, 1024.0 + (float(_6407 / _6247) * 11.0));\n        vec2 param_4 = _6422 + vec2(9.5, 10.5);\n        vec4 _6430 = fa_gi_fetch(param_4);\n        bool _6433 = _6430.y < 0.5;\n        bool _6442;\n        if (!_6433)\n        {\n            _6442 = _6430.x > _6156.y;\n        }\n        else\n        {\n            _6442 = _6433;\n        }\n        if (_6442)\n        {\n            continue;\n        }\n        vec3 _6454 = _6242 - (_6181 + (_6387 * _6174));\n        float _6457 = length(_6454);\n        vec3 _6463 = _6454 / vec3(max(_6457, 9.9999997473787516355514526367188e-05));\n        float _6473 = max(9.9999997473787516355514526367188e-05, (dot(-_6463, n) + 1.0) * 0.5);\n        float w = _6374 * (_6473 * _6473);\n        vec3 param_5 = _6463;\n        vec2 param_6 = (_6422 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _6492 = fa_gi_fetch(param_6);\n        float _6499 = _6457 / max(_6151.z, 9.9999997473787516355514526367188e-05);\n        float _6502 = _6492.x;\n        if (_6499 > _6502)\n        {\n            float _6515 = max(_6492.y - (_6502 * _6502), 0.0);\n            float _6520 = _6499 - _6502;\n            float _6529 = _6515 / max(_6515 + (_6520 * _6520), 9.9999999600419720025001879548654e-13);\n            w *= ((_6529 * _6529) * _6529);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _6422 + vec2(0.5, 10.5);\n        vec2 param_8 = _6422 + vec2(1.5, 10.5);\n        vec2 param_9 = _6422 + vec2(2.5, 10.5);\n        vec2 param_10 = _6422 + vec2(3.5, 10.5);\n        vec2 param_11 = _6422 + vec2(4.5, 10.5);\n        vec2 param_12 = _6422 + vec2(5.5, 10.5);\n        vec2 param_13 = _6422 + vec2(6.5, 10.5);\n        vec2 param_14 = _6422 + vec2(7.5, 10.5);\n        vec2 param_15 = _6422 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _6252)) + (fa_gi_fetch(param_9).xyz * _6256)) + (fa_gi_fetch(param_10).xyz * _6260)) + (fa_gi_fetch(param_11).xyz * _6267)) + (fa_gi_fetch(param_12).xyz * _6274)) + (fa_gi_fetch(param_13).xyz * _6283)) + (fa_gi_fetch(param_14).xyz * _6290)) + (fa_gi_fetch(param_15).xyz * _6303)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_6203 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _6655;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _6655 = _6156.x;\n    }\n    else\n    {\n        _6655 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_6151.w * _6655);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _6679 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _6684 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _6689 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _6689) && (k < 8); k++)\n    {\n        int param = _6684 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _6679;\n        vec3 _6714 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _6719 = param_3 * left;\n        acc += (_6714 * _6719);\n        left -= _6719;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _6748 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _6748;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[53].x > 0.5)\n    {\n        vec4 _6790 = vec4(fa_world_pos, 1.0);\n        vec2 _6809 = vec2(dot(fa_mesh_fs_params[26], _6790), dot(fa_mesh_fs_params[27], _6790)) / vec2(max(dot(fa_mesh_fs_params[28], _6790), 9.9999997473787516355514526367188e-05));\n        float _6818;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _6818 = (_6809.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _6818 = 0.5 - (_6809.y * 0.5);\n        }\n        return texelFetch(fa_lightmap_fa_env_smp, clamp(ivec2(vec2((_6809.x * 0.5) + 0.5, _6818) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4699 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4707 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4710 = int(_4699);\n    int _4713 = int(_4707);\n    float _4723 = _4707 - float(_4713);\n    int _4778 = (_4710 * 9) + _4713;\n    int _4798 = ((_4710 + 1) * 9) + _4713;\n    return mix(mix(_4774[_4778], _4774[_4778 + 1], _4723), mix(_4774[_4798], _4774[_4798 + 1], _4723), _4699 - float(_4710));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _7502 = false;\n    float _7503 = 1.0;\n    float _7504 = 1.0;\n    float _7505 = 1.0;\n    float _7506 = 0.0;\n    float _7507 = 0.0;\n    float _7508 = 0.0;\n    float _7509 = 0.0;\n    float _7511 = 1.0;\n    bool _7512 = false;\n    vec3 _7513 = vec3(0.0);\n    float _7514 = 1.0;\n    float _7515 = 1.0;\n    float _7516 = 1.0;\n    float _7517 = 0.0;\n    float _7518 = 0.0;\n    vec3 _7519 = vec3(1.0, 0.0, 0.0);\n    vec3 _7520 = vec3(0.0, 0.0, 1.0);\n    float _7521 = 1.0;\n    float _7522 = 1.0;\n    float _4849 = clamp(s.specular, 0.0, 1.0);\n    float _4853 = clamp(s.ior, 1.0, 3.0);\n    bool _4858 = (_4849 != 1.0) || (_4853 != 1.5);\n    bool _4867;\n    if (!_4858)\n    {\n        _4867 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4867 = _4858;\n    }\n    if (_4867)\n    {\n        float _4875 = (_4853 - 1.0) / (_4853 + 1.0);\n        f0 = mix(min(vec3(_4875 * _4875) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4849, s.albedo, vec3(metallic));\n        _7503 = mix(_4849, 1.0, metallic);\n        _7502 = true;\n    }\n    float _4902 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4902 > 0.0)\n    {\n        float _4910 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _7506 = _4902;\n        _7507 = _4910;\n        float _4917 = _4910 * _4910;\n        _7508 = _4917;\n        _7509 = _4917 * _4917;\n        float _4929 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _7511 = _4929;\n        _7504 = 1.0 - (_4902 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4929, 0.0, 1.0), 5.0))));\n        _7502 = true;\n    }\n    vec3 _4948 = max(s.sheen_color, vec3(0.0));\n    float _4957 = max(_4948.x, max(_4948.y, _4948.z));\n    if (_4957 > 0.0)\n    {\n        float _4965 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _7512 = true;\n        _7513 = _4948;\n        _7514 = _4965;\n        _7515 = _4965 * _4965;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4965;\n        float _4982 = fa_sheen_albedo(param, param_1);\n        _7517 = _4982;\n        _7516 = 1.0 - min(_4957 * _4982, 1.0);\n        _7502 = true;\n    }\n    _7505 = _7504 * _7516;\n    float _5001 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_5001 != 0.0)\n    {\n        vec3 _5016 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _5016;\n        if (dot(_5016, _5016) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _5028 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_5028.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _5028.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _5028.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _5032 = t;\n        vec3 _5033 = normalize(_5032);\n        t = _5033;\n        vec3 _5058 = normalize((_5033 * cos(s.anisotropy_rotation)) + ((cross(n, _5033) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _7519 = _5058;\n        _7520 = cross(n, _5058);\n        float _5068 = roughness * roughness;\n        float _5074 = mix(_5068, 1.0, _5001 * _5001);\n        bool _5076 = _5001 > 0.0;\n        _7521 = _5076 ? _5074 : _5068;\n        _7522 = _5076 ? _5068 : _5074;\n        _7518 = _5001;\n        _7502 = true;\n    }\n    return FaLayers(_7502, _7503, _7504, _7505, _7506, _7507, _7508, _7509, i.world_normal, _7511, _7512, _7513, _7514, _7515, _7516, _7517, _7518, _7519, _7520, _7521, _7522);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4631 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4634 = _4631.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4634 * _4634, exp2((-9.27999973297119140625) * ndv)) * _4634) + _4631.y)) + _4631.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3941;\n    if (lv == 0)\n    {\n        _3941 = 0.0;\n    }\n    else\n    {\n        _3941 = res + 2.0;\n    }\n    float _3951;\n    if (lv == 0)\n    {\n        _3951 = 0.0;\n    }\n    else\n    {\n        _3951 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3941, _3951)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3997;\n    if (res > 64.5)\n    {\n        _3997 = 5.0;\n    }\n    else\n    {\n        _3997 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _4012 = clamp(rough, 0.0, 1.0) * (_3997 - 1.0);\n    int _4019 = int(min(floor(_4012), _3997 - 2.0));\n    float _4024 = _4012 - float(_4019);\n    vec3 param = d;\n    vec2 _4028 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _4019;\n    vec2 param_4 = _4028;\n    vec3 _4038 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_4024 < 0.00200000009499490261077880859375)\n    {\n        return _4038;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _4019 + 1;\n    vec2 param_8 = _4028;\n    return mix(_4038, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_4024));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _4109 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _4116 = dot(by.xyz, fa_world_pos) + by.w;\n    float _4123 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _4129 = dot(bx.xyz, d);\n    float _4133 = dot(by.xyz, d);\n    float _4137 = dot(bz.xyz, d);\n    float _4143;\n    if (_4129 > 9.9999999747524270787835121154785e-07)\n    {\n        _4143 = (1.0 - _4109) / _4129;\n    }\n    else\n    {\n        float _4157;\n        if (_4129 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4157 = ((-1.0) - _4109) / _4129;\n        }\n        else\n        {\n            _4157 = 1000000015047466219876688855040.0;\n        }\n        _4143 = _4157;\n    }\n    float tx = _4143;\n    float _4174;\n    if (_4133 > 9.9999999747524270787835121154785e-07)\n    {\n        _4174 = (1.0 - _4116) / _4133;\n    }\n    else\n    {\n        float _4187;\n        if (_4133 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4187 = ((-1.0) - _4116) / _4133;\n        }\n        else\n        {\n            _4187 = 1000000015047466219876688855040.0;\n        }\n        _4174 = _4187;\n    }\n    float ty = _4174;\n    float _4203;\n    if (_4137 > 9.9999999747524270787835121154785e-07)\n    {\n        _4203 = (1.0 - _4123) / _4137;\n    }\n    else\n    {\n        float _4216;\n        if (_4137 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4216 = ((-1.0) - _4123) / _4137;\n        }\n        else\n        {\n            _4216 = 1000000015047466219876688855040.0;\n        }\n        _4203 = _4216;\n    }\n    float _4228 = tx;\n    float _4231 = (_4228 > 0.0) ? _4228 : 1000000015047466219876688855040.0;\n    tx = _4231;\n    float _4232 = ty;\n    float _4235 = (_4232 > 0.0) ? _4232 : 1000000015047466219876688855040.0;\n    ty = _4235;\n    float _4245 = min(_4231, min(_4235, (_4203 > 0.0) ? _4203 : 1000000015047466219876688855040.0));\n    if (_4245 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4261 = (fa_world_pos + (d * _4245)) - posw.xyz;\n    vec3 _4266;\n    if (dot(_4261, _4261) > 1.0000000133514319600180897396058e-10)\n    {\n        _4266 = normalize(_4261);\n    }\n    else\n    {\n        _4266 = d;\n    }\n    return _4266;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4312 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4312 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4340 = rough * rough;\n            float _4371 = 0.60000002384185791015625 * _4340;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4340)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4371, 0.0500000007450580596923828125 + _4371, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4340 * 0.60000002384185791015625));\n        }\n        outc = base * _4312;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4430 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4430 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4462 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4462 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _5109;\n        if (L.aniso >= 0.0)\n        {\n            _5109 = L.b;\n        }\n        else\n        {\n            _5109 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_5109, v), _5109), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5145 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _5145.x) + (vec3(L.f90) * _5145.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _5203 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _5203.x) + _5203.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4673 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4673.x) + vec3(_4673.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _5232 = clamp(s.metallic, 0.0, 1.0);\n    float _5236 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _5243 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_5232));\n    vec3 f0 = _5243;\n    vec3 _5247 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _5247;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _5232;\n    float param_5 = _5236;\n    vec3 param_6 = _5243;\n    FaLayers _5264 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_5264.on)\n    {\n        FaLayers param_7 = _5264;\n        vec3 param_8 = _5247;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _5236;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    vec3 param_13 = _5247;\n    vec3 param_14 = i.view_dir;\n    vec3 param_15 = f0;\n    float param_16 = _5236;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5559;\n    if (fa_lm.z > 0.5)\n    {\n        _5559 = 0.0;\n    }\n    else\n    {\n        _5559 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5570 = _5559 < 1.0;\n    bool _5576;\n    if (_5570)\n    {\n        int param = li;\n        _5576 = fa_light_baked(param);\n    }\n    else\n    {\n        _5576 = _5570;\n    }\n    return _5576 ? _5559 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _695 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _708 = (c - (ru * hx)) - p;\n        vec3 _714 = ru * (2.0 * hx);\n        float _720 = max(dot(_714, _714), 9.9999999392252902907785028219223e-09);\n        float _724 = dot(_708, _714);\n        float t = clamp((-_724) / _720, 0.0, 1.0);\n        if (_695)\n        {\n            float _739 = dot(r, _714);\n            float _745 = _720 - (_739 * _739);\n            if (abs(_745) > (9.9999997473787516355514526367188e-06 * _720))\n            {\n                t = clamp(((dot(r, _708) * _739) - _724) / _745, 0.0, 1.0);\n            }\n        }\n        return (p + _708) + (_714 * t);\n    }\n    vec3 q = p;\n    float _777 = dot(r, axis);\n    bool _785;\n    if (_695)\n    {\n        _785 = abs(_777) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _785 = _695;\n    }\n    if (_785)\n    {\n        float _795 = dot(c - p, axis) / _777;\n        if (_795 > 0.0)\n        {\n            q = p + (r * _795);\n        }\n    }\n    vec3 _808 = q - c;\n    vec2 xy = vec2(dot(_808, ru), dot(_808, uu));\n    if (shape > 0.5)\n    {\n        float _823 = length(xy);\n        if (_823 > hx)\n        {\n            xy *= (hx / _823);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _615 = dot(d, right);\n    float _619 = dot(d, up);\n    float _630;\n    if (((_615 * _615) + (_619 * _619)) > 1.0000000133514319600180897396058e-10)\n    {\n        _630 = atan(_619, _615) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _630 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_630 - floor(_630)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _466 = abs(d);\n    float _468 = _466.x;\n    float _470 = _466.y;\n    bool _471 = _468 >= _470;\n    bool _479;\n    if (_471)\n    {\n        _479 = _468 >= _466.z;\n    }\n    else\n    {\n        _479 = _471;\n    }\n    int _480;\n    if (_479)\n    {\n        _480 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _494;\n        if (_470 >= _466.z)\n        {\n            _494 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _494 = (d.z > 0.0) ? 4 : 5;\n        }\n        _480 = _494;\n    }\n    return _480;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _861 = fa_light_base(param);\n    bool _865 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _861;\n    vec4 _869 = fa_light_texel(param_1);\n    int param_2 = _861 + 1;\n    vec4 _874 = fa_light_texel(param_2);\n    float _877 = _874.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _889 = _865 && (_877 > 2.5);\n    fa_light_is_area = _889;\n    bool _891 = _877 < 0.5;\n    vec3 l;\n    if (_891)\n    {\n        l = normalize(_869.xyz);\n        if (_865)\n        {\n            int param_3 = _861 + 6;\n            vec4 _905 = fa_light_texel(param_3);\n            if (_905.z > 0.5)\n            {\n                int param_4 = _861 + 4;\n                vec4 _915 = fa_light_texel(param_4);\n                int param_5 = _861 + 5;\n                vec4 _920 = fa_light_texel(param_5);\n                vec2 param_6 = _905.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _915.xyz) * _915.w, (-dot(world_pos, _920.xyz)) * _920.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _950 = _869.xyz;\n        vec3 _952 = _950 - world_pos;\n        vec3 to_light = _952;\n        float _955 = length(_952);\n        float reach = _955;\n        bool front = true;\n        if (_889)\n        {\n            int param_8 = _861 + 7;\n            reach = max(_955 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _861 + 4;\n            vec4 _979 = fa_light_texel(param_9);\n            int param_10 = _861 + 5;\n            vec4 _984 = fa_light_texel(param_10);\n            int param_11 = _861 + 6;\n            vec4 _989 = fa_light_texel(param_11);\n            float _990 = _989.w;\n            int param_12 = _861 + 2;\n            vec3 _997 = normalize(fa_light_texel(param_12).xyz);\n            bool _999 = _990 > 1.5;\n            bool _1007;\n            if (!_999)\n            {\n                _1007 = dot(_997, to_light) < 0.0;\n            }\n            else\n            {\n                _1007 = _999;\n            }\n            front = _1007;\n            vec3 r = vec3(0.0);\n            vec3 _1016 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1020 = dot(n, n) > 0.5;\n            bool _1028;\n            if (_1020)\n            {\n                _1028 = dot(_1016, _1016) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1028 = _1020;\n            }\n            if (_1028)\n            {\n                r = reflect(-normalize(_1016), normalize(n));\n            }\n            vec3 param_13 = _950;\n            vec3 param_14 = _997;\n            vec3 param_15 = _979.xyz;\n            vec3 param_16 = _984.xyz;\n            float param_17 = _979.w;\n            float param_18 = _984.w;\n            float param_19 = _990;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1064 = length(to_light);\n        dist = _1064;\n        l = to_light / vec3(max(_1064, 9.9999997473787516355514526367188e-05));\n        float _1078 = reach / max(_869.w, 0.001000000047497451305389404296875);\n        float _1084 = clamp(1.0 - (_1078 * _1078), 0.0, 1.0);\n        float _1086;\n        if (front)\n        {\n            _1086 = _1084 * _1084;\n        }\n        else\n        {\n            _1086 = 0.0;\n        }\n        atten = _1086;\n        bool _1097 = _877 < 2.5;\n        if ((_877 > 1.5) && _1097)\n        {\n            int param_22 = _861 + 2;\n            vec4 _1105 = fa_light_texel(param_22);\n            float _1115 = _1105.w;\n            int param_23 = _861 + 3;\n            vec4 _1120 = fa_light_texel(param_23);\n            float _1121 = _1120.x;\n            float cos_inner = _1121;\n            if (_1121 > 1.5)\n            {\n                cos_inner = mix(_1115, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1115, cos_inner, dot(-l, normalize(_1105.xyz)));\n        }\n        if (_865 && (_877 < 1.5))\n        {\n            int param_24 = _861 + 6;\n            vec4 _1145 = fa_light_texel(param_24);\n            if (_1145.z > 0.5)\n            {\n                vec3 _1153 = -to_light;\n                int param_25 = _861 + 4;\n                int param_26 = _861 + 5;\n                vec3 _1167 = fa_light_texel(param_25).xyz;\n                vec3 _1171 = fa_light_texel(param_26).xyz;\n                vec3 _1180 = vec3(dot(_1153, _1167), dot(_1153, _1171), dot(_1153, cross(_1167, _1171)));\n                vec3 param_27 = _1180;\n                int _1184 = fa_cube_face(param_27);\n                int param_28 = _1184;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1211 = vec2(dot(_1180, cross(param_29, param_30)), dot(_1180, param_30)) / vec2(max(dot(_1180, param_29), 9.9999997473787516355514526367188e-05));\n                int _1215 = _1184 / 3;\n                vec2 param_31 = _1145.xy + (vec2(float(_1184 - (_1215 * 3)), float(_1215)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1211.x), 0.5 - (0.5 * _1211.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _861 + 7;\n            vec4 _1245 = fa_light_texel(param_33);\n            if (_1245.z > 0.5)\n            {\n                int param_34 = _861 + 2;\n                int param_35 = _861 + 4;\n                int param_36 = _861 + 5;\n                vec2 param_37 = _1245.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_865 && _1097)\n            {\n                int param_42 = _861 + 6;\n                vec4 _1292 = fa_light_texel(param_42);\n                int param_43 = _861 + 7;\n                vec4 _1297 = fa_light_texel(param_43);\n                bool _1300 = _1292.z > 0.5;\n                bool _1307;\n                if (!_1300)\n                {\n                    _1307 = _1297.z > 0.5;\n                }\n                else\n                {\n                    _1307 = _1300;\n                }\n                if (_1307)\n                {\n                    int param_44 = _861 + 2;\n                    vec4 _1314 = fa_light_texel(param_44);\n                    vec3 _1318 = normalize(_1314.xyz);\n                    int param_45 = _861 + 4;\n                    vec4 _1323 = fa_light_texel(param_45);\n                    int param_46 = _861 + 5;\n                    vec4 _1328 = fa_light_texel(param_46);\n                    if (_1300)\n                    {\n                        vec3 _1336 = -to_light;\n                        float _1343 = _1314.w;\n                        float _1359 = 0.5 / max(dot(_1336, _1318) * (sqrt(max(1.0 - (_1343 * _1343), 0.0)) / max(_1343, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1292.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1336, _1323.xyz) * _1359), 0.5 - (dot(_1336, _1328.xyz) * _1359));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1297.z > 0.5)\n                    {\n                        vec2 param_49 = _1297.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1318;\n                        vec3 param_52 = _1323.xyz;\n                        vec3 param_53 = _1328.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _7490 = _874.xyz * atten;\n    if (_865)\n    {\n        _7490 *= fa_light_tint;\n    }\n    int _1427;\n    if (_891)\n    {\n        _1427 = 0;\n    }\n    else\n    {\n        _1427 = ((_877 > 1.5) && (_877 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _7490, atten, 1.0, dist, _1427);\n}\n\nfloat fa_rt_local_tap(ivec2 p, ivec2 size, float d, float tol, float div, inout float best)\n{\n    vec4 _3388 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(p, ivec2(0), size - ivec2(1)), 0);\n    bool _3391 = _3388.w > 0.5;\n    bool _3401;\n    if (_3391)\n    {\n        _3401 = abs(d - _3388.x) <= tol;\n    }\n    else\n    {\n        _3401 = _3391;\n    }\n    if (_3401)\n    {\n        best = min(best, mod(floor(_3388.z / div), 256.0) * 0.0039215688593685626983642578125);\n    }\n    return best;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2216 = fa_shadow_depth(param, param_1);\n    float _2220;\n    if (conv.x < 0.5)\n    {\n        _2220 = _2216;\n    }\n    else\n    {\n        _2220 = (conv.y * conv.z) / (conv.z - (_2216 * (conv.z - conv.y)));\n    }\n    return _2220;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2266 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2272 = vec2(cos(_2266), sin(_2266));\n    vec2 dir = _2272;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2281;\n        if (k < 0.0)\n        {\n            _2281 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2281 = k;\n        }\n        float _2300 = clamp((_2281 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2319 = sqrt((float(i) + 0.5) * 0.0625) * _2300;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2319));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2333 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2333 < (zr - (_2319 * plane)))\n            {\n                sum += _2333;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2361 = sum / cnt;\n        float _2371;\n        if (k < 0.0)\n        {\n            _2371 = (-k) / max(_2361, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2371 = k;\n        }\n        radius = clamp(((max(zr - _2361, 0.0) * unit) * _2371) / texel_m, 1.5, 16.0);\n        dir = _2272;\n    }\n    float lit = 0.0;\n    int _2397 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2397; i_1++)\n    {\n        float _2416 = sqrt((float(i_1) + 0.5) / float(_2397)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2416));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2416 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2397);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2621 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2628;\n    if (!_2621)\n    {\n        _2628 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2628 = _2621;\n    }\n    if (_2628)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2641 = fa_light_texel(param);\n    float _2642 = _2641.x;\n    if (_2642 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2651 = int(_2642 + 0.5);\n    int param_1 = _2651;\n    vec4 _2655 = fa_light_texel(param_1);\n    int param_2 = _2651 + 1;\n    vec4 _2660 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2663 = _2655.y;\n    if (_2663 > 0.0)\n    {\n        float _2680 = 1.0 - smoothstep(0.75 * _2663, _2663, length(world - fa_shadows[27].xyz));\n        fade = _2680;\n        if (_2680 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2655.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2704 = (_2651 + 2) + (face * 6);\n    int param_4 = _2704;\n    int param_5 = _2704 + 1;\n    int param_6 = _2704 + 3;\n    vec4 _2718 = fa_light_texel(param_6);\n    int param_7 = _2704 + 4;\n    vec4 _2723 = fa_light_texel(param_7);\n    int param_8 = _2704 + 5;\n    vec4 _2728 = fa_light_texel(param_8);\n    float _2740 = _2728.x * max(dot(_2718, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2745 = clamp(dot(n, l), 0.0, 1.0);\n    float _2768 = clamp(dot(n, _2718.xyz), -1.0, 1.0);\n    float _2787 = min(sqrt(1.0 - (_2768 * _2768)) / max(abs(dot(n, world - lpos)) / max(dot(_2718, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2790 = _2660.y;\n    float _2792;\n    if (_2790 > 0.0)\n    {\n        _2792 = _2790;\n    }\n    else\n    {\n        _2792 = 1.5 * _2740;\n    }\n    vec4 _2812 = vec4(world + (n * (_2792 * sqrt(1.0 - (_2745 * _2745)))), 1.0);\n    float _2816 = dot(_2718, _2812);\n    float _2819 = _2728.y;\n    if (_2816 < _2819)\n    {\n        return 1.0;\n    }\n    vec2 _2834 = vec2(dot(fa_light_texel(param_4), _2812), dot(fa_light_texel(param_5), _2812)) / vec2(_2816);\n    float _2836 = _2834.x;\n    bool _2839 = _2836 < _2723.x;\n    bool _2848;\n    if (!_2839)\n    {\n        _2848 = _2836 > _2723.z;\n    }\n    else\n    {\n        _2848 = _2839;\n    }\n    bool _2857;\n    if (!_2848)\n    {\n        _2857 = _2834.y < _2723.y;\n    }\n    else\n    {\n        _2857 = _2848;\n    }\n    bool _2866;\n    if (!_2857)\n    {\n        _2866 = _2834.y > _2723.w;\n    }\n    else\n    {\n        _2866 = _2857;\n    }\n    if (_2866)\n    {\n        return 1.0;\n    }\n    float _2872 = _2660.x;\n    float _2874;\n    if (_2872 > 0.0)\n    {\n        _2874 = _2872;\n    }\n    else\n    {\n        _2874 = 1.5 * _2740;\n    }\n    vec2 param_9 = _2834;\n    vec4 param_10 = _2723;\n    float param_11 = _2816 - (_2874 * (1.0 + (0.5 * _2787)));\n    float param_12 = _2740;\n    float param_13 = 1.0;\n    float param_14 = _2728.z * 0.25;\n    float param_15 = (_2740 * min(_2787, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2819, _2728.z);\n    int param_17 = int(_2655.z + 0.5);\n    float param_18 = _2655.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3419 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3425;\n    if (_3419)\n    {\n        _3425 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3425 = _3419;\n    }\n    bool _3431;\n    if (_3425)\n    {\n        _3431 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3431 = _3425;\n    }\n    if (_3431)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3443 = fa_light_texel(param);\n        float _3444 = _3443.z;\n        if (_3444 > 0.5)\n        {\n            float _3457 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3463 = ((0.00200000009499490261077880859375 * _3457) + 0.00999999977648258209228515625) + fa_rt_slope;\n            vec4 _3469 = vec4(world, 1.0);\n            float _3474 = dot(fa_mesh_fs_params[28], _3469);\n            if (_3474 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3491 = vec2(dot(fa_mesh_fs_params[26], _3469), dot(fa_mesh_fs_params[27], _3469)) / vec2(_3474);\n                float _3496 = (_3491.x * 0.5) + 0.5;\n                float _3500;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3500 = (_3491.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3500 = 0.5 - (_3491.y * 0.5);\n                }\n                bool _3516 = _3496 >= 0.0;\n                bool _3522;\n                if (_3516)\n                {\n                    _3522 = _3496 < 1.0;\n                }\n                else\n                {\n                    _3522 = _3516;\n                }\n                bool _3528;\n                if (_3522)\n                {\n                    _3528 = _3500 >= 0.0;\n                }\n                else\n                {\n                    _3528 = _3522;\n                }\n                bool _3534;\n                if (_3528)\n                {\n                    _3534 = _3500 < 1.0;\n                }\n                else\n                {\n                    _3534 = _3528;\n                }\n                if (_3534)\n                {\n                    ivec2 _3541 = ivec2(fa_mesh_fs_params[24].zw);\n                    ivec2 _3552 = clamp(ivec2(vec2(_3496, _3500) * fa_mesh_fs_params[24].zw), ivec2(0), _3541 - ivec2(1));\n                    float _3556;\n                    if (_3444 < 1.5)\n                    {\n                        _3556 = 1.0;\n                    }\n                    else\n                    {\n                        _3556 = (_3444 < 2.5) ? 256.0 : 65536.0;\n                    }\n                    float best = 2.0;\n                    vec4 _3572 = texelFetch(fa_screen_tex_fa_shadow_smp, _3552, 0);\n                    bool _3575 = _3572.w > 0.5;\n                    bool _3585;\n                    if (_3575)\n                    {\n                        _3585 = abs(_3457 - _3572.x) <= _3463;\n                    }\n                    else\n                    {\n                        _3585 = _3575;\n                    }\n                    if (_3585)\n                    {\n                        best = mod(floor(_3572.z / _3556), 256.0) * 0.0039215688593685626983642578125;\n                    }\n                    else\n                    {\n                        ivec2 param_1 = _3552 + ivec2(-1);\n                        ivec2 param_2 = _3541;\n                        float param_3 = _3457;\n                        float param_4 = _3463;\n                        float param_5 = _3556;\n                        float param_6 = best;\n                        float _3611 = fa_rt_local_tap(param_1, param_2, param_3, param_4, param_5, param_6);\n                        best = _3611;\n                        ivec2 param_7 = _3552 + ivec2(0, -1);\n                        ivec2 param_8 = _3541;\n                        float param_9 = _3457;\n                        float param_10 = _3463;\n                        float param_11 = _3556;\n                        float param_12 = _3611;\n                        float _3626 = fa_rt_local_tap(param_7, param_8, param_9, param_10, param_11, param_12);\n                        best = _3626;\n                        ivec2 param_13 = _3552 + ivec2(1, -1);\n                        ivec2 param_14 = _3541;\n                        float param_15 = _3457;\n                        float param_16 = _3463;\n                        float param_17 = _3556;\n                        float param_18 = _3626;\n                        float _3641 = fa_rt_local_tap(param_13, param_14, param_15, param_16, param_17, param_18);\n                        best = _3641;\n                        ivec2 param_19 = _3552 + ivec2(-1, 0);\n                        ivec2 param_20 = _3541;\n                        float param_21 = _3457;\n                        float param_22 = _3463;\n                        float param_23 = _3556;\n                        float param_24 = _3641;\n                        float _3656 = fa_rt_local_tap(param_19, param_20, param_21, param_22, param_23, param_24);\n                        best = _3656;\n                        ivec2 param_25 = _3552 + ivec2(1, 0);\n                        ivec2 param_26 = _3541;\n                        float param_27 = _3457;\n                        float param_28 = _3463;\n                        float param_29 = _3556;\n                        float param_30 = _3656;\n                        float _3671 = fa_rt_local_tap(param_25, param_26, param_27, param_28, param_29, param_30);\n                        best = _3671;\n                        ivec2 param_31 = _3552 + ivec2(-1, 1);\n                        ivec2 param_32 = _3541;\n                        float param_33 = _3457;\n                        float param_34 = _3463;\n                        float param_35 = _3556;\n                        float param_36 = _3671;\n                        float _3686 = fa_rt_local_tap(param_31, param_32, param_33, param_34, param_35, param_36);\n                        best = _3686;\n                        ivec2 param_37 = _3552 + ivec2(0, 1);\n                        ivec2 param_38 = _3541;\n                        float param_39 = _3457;\n                        float param_40 = _3463;\n                        float param_41 = _3556;\n                        float param_42 = _3686;\n                        float _3701 = fa_rt_local_tap(param_37, param_38, param_39, param_40, param_41, param_42);\n                        best = _3701;\n                        ivec2 param_43 = _3552 + ivec2(1);\n                        ivec2 param_44 = _3541;\n                        float param_45 = _3457;\n                        float param_46 = _3463;\n                        float param_47 = _3556;\n                        float param_48 = _3701;\n                        float _3716 = fa_rt_local_tap(param_43, param_44, param_45, param_46, param_47, param_48);\n                        best = _3716;\n                    }\n                    if (best <= 1.0)\n                    {\n                        float _3724;\n                        if (fa_mesh_fs_params[25].z > 0.5)\n                        {\n                            int param_49 = li;\n                            vec3 param_50 = lpos;\n                            vec3 param_51 = world;\n                            vec3 param_52 = n;\n                            vec3 param_53 = l;\n                            _3724 = min(best, fa_shadow_local(param_49, param_50, param_51, param_52, param_53));\n                        }\n                        else\n                        {\n                            _3724 = best;\n                        }\n                        return _3724;\n                    }\n                }\n            }\n            float _3747;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_54 = li;\n                vec3 param_55 = lpos;\n                vec3 param_56 = world;\n                vec3 param_57 = n;\n                vec3 param_58 = l;\n                _3747 = fa_shadow_local(param_54, param_55, param_56, param_57, param_58);\n            }\n            else\n            {\n                _3747 = 1.0;\n            }\n            return _3747;\n        }\n    }\n    int param_59 = li;\n    vec3 param_60 = lpos;\n    vec3 param_61 = world;\n    vec3 param_62 = n;\n    vec3 param_63 = l;\n    return fa_shadow_local(param_59, param_60, param_61, param_62, param_63);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2159;\n    if (i == 0)\n    {\n        _2159 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2175;\n        if (i == 1)\n        {\n            _2175 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2183;\n            if (i == 2)\n            {\n                _2183 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2183 = fa_shadows[24].w;\n            }\n            _2175 = _2183;\n        }\n        _2159 = _2175;\n    }\n    return _2159;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2462 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2467 = clamp(dot(n, l), 0.0, 1.0);\n    float _2473 = sqrt(1.0 - (_2467 * _2467));\n    float _2481 = min(_2473 / max(_2467, 0.20000000298023223876953125), 4.0);\n    float _2486;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2486 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2486 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2511 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2486 * _2473)), 1.0);\n    float _2518 = _2511.x;\n    bool _2521 = _2518 < fa_shadows[ci * 1 + 16].x;\n    bool _2530;\n    if (!_2521)\n    {\n        _2530 = _2518 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2530 = _2521;\n    }\n    bool _2539;\n    if (!_2530)\n    {\n        _2539 = _2511.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2539 = _2530;\n    }\n    bool _2548;\n    if (!_2539)\n    {\n        _2548 = _2511.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2548 = _2539;\n    }\n    bool _2555;\n    if (!_2548)\n    {\n        _2555 = _2511.z > 1.0;\n    }\n    else\n    {\n        _2555 = _2548;\n    }\n    if (_2555)\n    {\n        return -1.0;\n    }\n    float _2563;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2563 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2563 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2511.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2511.z - ((_2563 * (1.0 + (0.5 * _2481))) / _2462);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2462;\n    float param_5 = _2462 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2481, 3.0)) * 0.5) / _2462;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2941 = int(fa_shadows[25].x + 0.5);\n    if (_2941 < 1)\n    {\n        return 1.0;\n    }\n    float _2956 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2941 - 1;\n    if (_2956 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2968 = _2941 > 1;\n    bool _2975;\n    if (_2968)\n    {\n        _2975 = _2956 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2975 = _2968;\n    }\n    if (_2975)\n    {\n        ci = 1;\n    }\n    bool _2979 = _2941 > 2;\n    bool _2986;\n    if (_2979)\n    {\n        _2986 = _2956 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2986 = _2979;\n    }\n    if (_2986)\n    {\n        ci = 2;\n    }\n    bool _2990 = _2941 > 3;\n    bool _2997;\n    if (_2990)\n    {\n        _2997 = _2956 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2997 = _2990;\n    }\n    if (_2997)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3008 = min(_2941, 4);\n    float _3049;\n    for (int c = ci; c < _3008; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3028 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3028;\n            break;\n        }\n        if (_3028 < 0.0)\n        {\n            continue;\n        }\n        s = _3028;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3049 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3049 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3068 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3049, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2956 - (fa_shadow_split_at(param_7) - _3068)) / _3068, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3100;\n        if ((ci + 1) < _2941)\n        {\n            _3100 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3100 = 1.0;\n        }\n        s = mix(s, _3100, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3205 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3211;\n    if (_3205)\n    {\n        _3211 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3211 = _3205;\n    }\n    if (_3211)\n    {\n        float _3225 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        vec4 _3233 = vec4(fa_world_pos, 1.0);\n        float _3239 = dot(fa_mesh_fs_params[28], _3233);\n        if (_3239 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3258 = vec2(dot(fa_mesh_fs_params[26], _3233), dot(fa_mesh_fs_params[27], _3233)) / vec2(_3239);\n            float _3263 = (_3258.x * 0.5) + 0.5;\n            float _3267;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3267 = (_3258.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3267 = 0.5 - (_3258.y * 0.5);\n            }\n            bool _3283 = _3263 >= 0.0;\n            bool _3289;\n            if (_3283)\n            {\n                _3289 = _3263 < 1.0;\n            }\n            else\n            {\n                _3289 = _3283;\n            }\n            bool _3295;\n            if (_3289)\n            {\n                _3295 = _3267 >= 0.0;\n            }\n            else\n            {\n                _3295 = _3289;\n            }\n            bool _3301;\n            if (_3295)\n            {\n                _3301 = _3267 < 1.0;\n            }\n            else\n            {\n                _3301 = _3295;\n            }\n            if (_3301)\n            {\n                vec4 _3326 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3263, _3267) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3329 = _3326.w > 0.5;\n                bool _3345;\n                if (_3329)\n                {\n                    _3345 = abs(_3225 - _3326.x) <= (((0.00200000009499490261077880859375 * _3225) + 0.00999999977648258209228515625) + fa_rt_slope);\n                }\n                else\n                {\n                    _3345 = _3329;\n                }\n                if (_3345)\n                {\n                    float _3351;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3351 = min(_3326.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3351 = _3326.y;\n                    }\n                    return _3351;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5303 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5310;\n    if (!_5303)\n    {\n        _5310 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5310 = _5303;\n    }\n    if (_5310)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5323 = fa_light_texel(param);\n    float _5324 = _5323.y;\n    float len = _5324;\n    if (_5324 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5336 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5345 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5336);\n    if (_5345 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5351 = len;\n    float _5354 = min(_5351, 0.89999997615814208984375 * dist);\n    len = _5354;\n    float _5359 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5336);\n    float _5364 = _5359 + (0.5 * _5354);\n    vec3 _5370 = world + (gn * _5359);\n    float _5372 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5433;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5387 = (float(k) + _5372) * 0.083333335816860198974609375;\n        vec3 _5395 = _5370 + (l * (_5387 * len));\n        vec4 _5401 = vec4(_5395, 1.0);\n        float _5406 = dot(fa_mesh_fs_params[28], _5401);\n        if (_5406 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5424 = vec2(dot(fa_mesh_fs_params[26], _5401), dot(fa_mesh_fs_params[27], _5401)) / vec2(_5406);\n        float _5428 = _5424.x * 0.5;\n        float _5429 = _5428 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5433 = (_5424.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5433 = 0.5 - (_5424.y * 0.5);\n        }\n        bool _5449 = _5429 < 0.0;\n        bool _5456;\n        if (!_5449)\n        {\n            _5456 = _5429 >= 1.0;\n        }\n        else\n        {\n            _5456 = _5449;\n        }\n        bool _5463;\n        if (!_5456)\n        {\n            _5463 = _5433 < 0.0;\n        }\n        else\n        {\n            _5463 = _5456;\n        }\n        bool _5470;\n        if (!_5463)\n        {\n            _5470 = _5433 >= 1.0;\n        }\n        else\n        {\n            _5470 = _5463;\n        }\n        if (_5470)\n        {\n            break;\n        }\n        vec4 _5494 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5429, _5433) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5494.w < 0.5)\n        {\n            continue;\n        }\n        float _5512 = (dot(fa_mesh_fs_params[29].xyz, _5395) + fa_mesh_fs_params[29].w) - _5494.x;\n        if ((_5512 > _5359) && (_5512 < _5364))\n        {\n            occ = max(occ, (1.0 - (_5387 * _5387)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5429, 0.5 - _5428), min(_5433, 1.0 - _5433))));\n        }\n    }\n    return 1.0 - (occ * _5345);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5644 = fa_baked_keep(param);\n    if (_5644 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5670 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _7623 = _5670.color;\n    float _7624 = _5670.attenuation;\n    float _7625 = _5670.shadow;\n    bool _5673 = _5670.type == 0;\n    if (_5673 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5670.direction;\n        float _5684 = fa_shadow_factor(param_5, param_6);\n        _7625 = _5684;\n        _7623 *= _5684;\n    }\n    else\n    {\n        bool _5695 = _5670.type != 0;\n        bool _5701;\n        if (_5695)\n        {\n            _5701 = _7624 > 0.0;\n        }\n        else\n        {\n            _5701 = _5695;\n        }\n        if (_5701)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5670.direction;\n            float _5720 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _7625 = _5720;\n            _7623 *= _5720;\n        }\n    }\n    bool _5730 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5736;\n    if (_5730)\n    {\n        _5736 = _7624 > 0.0;\n    }\n    else\n    {\n        _5736 = _5730;\n    }\n    if (_5736)\n    {\n        float _5743;\n        if (_5673)\n        {\n            _5743 = 1000000000.0;\n        }\n        else\n        {\n            _5743 = _5670._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5670.direction;\n        float param_18 = _5743;\n        float _5761 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7625 *= _5761;\n        _7623 *= _5761;\n    }\n    float _5774 = _7624;\n    float _5775 = _5774 * _5644;\n    _7624 = _5775;\n    vec3 _5779 = _7623;\n    vec3 _5780 = _5779 * _5644;\n    _7623 = _5780;\n    return LightSample(_5670.direction, _5780, _5775, _7625, _5670._distance, _5670.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3128 = int(fa_shadows[25].x + 0.5);\n    float _3138 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3143 = _3128 > 0;\n    bool _3152;\n    if (_3143)\n    {\n        int param = _3128 - 1;\n        _3152 = _3138 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3152 = _3143;\n    }\n    if (_3152)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3158 = _3128 > 1;\n        bool _3165;\n        if (_3158)\n        {\n            _3165 = _3138 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3165 = _3158;\n        }\n        if (_3165)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3171 = _3128 > 2;\n        bool _3178;\n        if (_3171)\n        {\n            _3178 = _3138 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3178 = _3171;\n        }\n        if (_3178)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3184 = _3128 > 3;\n        bool _3191;\n        if (_3184)\n        {\n            _3191 = _3138 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3191 = _3184;\n        }\n        if (_3191)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_rt_slope = 0.0;\n    fa_inst_load();\n    vec3 _7308 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _7308 = -_7308;\n    }\n    vec3 _6931 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _7308, fa_world_tangent, fa_uv, fa_vertex_color, _6931, gl_FrontFacing);\n    Surface _6939 = fa_standard_surface(param_1);\n    vec3 _7347 = _6939.albedo;\n    float _7348 = _6939.alpha;\n    vec3 _7349 = _6939.normal;\n    float _7350 = _6939.metallic;\n    float _7351 = _6939.roughness;\n    float _7352 = _6939.occlusion;\n    vec3 _7353 = _6939.emission;\n    float _7354 = _6939.clearcoat;\n    float _7355 = _6939.clearcoat_roughness;\n    vec3 _7356 = _6939.sheen_color;\n    float _7357 = _6939.sheen_roughness;\n    float _7358 = _6939.anisotropy;\n    float _7359 = _6939.anisotropy_rotation;\n    float _7360 = _6939.specular;\n    float _7361 = _6939.ior;\n    vec3 _7362 = _6939.specular_color;\n    float _7363 = _6939.transmission;\n    float _7364 = _6939.thickness;\n    vec3 _7365 = _6939.attenuation_color;\n    float _7366 = _6939.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _7308, fa_world_tangent, fa_uv, fa_vertex_color, _6931, gl_FrontFacing);\n    Surface param_3 = _6939;\n    surface(param_2, param_3);\n    _7347 = param_3.albedo;\n    _7348 = param_3.alpha;\n    _7349 = param_3.normal;\n    _7350 = param_3.metallic;\n    _7351 = param_3.roughness;\n    _7352 = param_3.occlusion;\n    _7353 = param_3.emission;\n    _7354 = param_3.clearcoat;\n    _7355 = param_3.clearcoat_roughness;\n    _7356 = param_3.sheen_color;\n    _7357 = param_3.sheen_roughness;\n    _7358 = param_3.anisotropy;\n    _7359 = param_3.anisotropy_rotation;\n    _7360 = param_3.specular;\n    _7361 = param_3.ior;\n    _7362 = param_3.specular_color;\n    _7363 = param_3.transmission;\n    _7364 = param_3.thickness;\n    _7365 = param_3.attenuation_color;\n    _7366 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _7308;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _7347 = param_6;\n    _7349 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _7347;\n    }\n    else\n    {\n        vec3 _6978 = _7349;\n        vec3 _6979 = normalize(_6978);\n        _7349 = _6979;\n        vec3 param_8 = _6979;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _7308, fa_world_tangent, fa_uv, fa_vertex_color, _6931, gl_FrontFacing);\n        Surface param_10 = Surface(_7347, _7348, _7349, _7350, _7351, _7352, _7353, _7354, _7355, _7356, _7357, _7358, _7359, _7360, _7361, _7362, _7363, _7364, _7365, _7366);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _6998 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6998; ln++)\n        {\n            int param_12 = ln;\n            int _7011 = fa_cl_light(param_12);\n            int param_13 = _7011;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _7011;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _7308;\n            LightSample _7027 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _7308, fa_world_tangent, fa_uv, fa_vertex_color, _6931, gl_FrontFacing);\n            Surface param_18 = Surface(_7347, _7348, _7349, _7350, _7351, _7352, _7353, _7354, _7355, _7356, _7357, _7358, _7359, _7360, _7361, _7362, _7363, _7364, _7365, _7366);\n            LightSample param_19 = _7027;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _7042 = result;\n    vec3 _7043 = _7042 + _7353;\n    result = _7043;\n    vec3 param_20 = _7043;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _7052 = fa_mesh_fs_params[7].w > 0.0;\n    bool _7059;\n    if (!_7052)\n    {\n        _7059 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _7059 = _7052;\n    }\n    if (_7059)\n    {\n        vec3 _7068 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _7074 = dot(_7068, fa_mesh_fs_params[9].xyz);\n        bool _7078 = fa_mesh_fs_params[9].w > 0.5;\n        float _7079;\n        if (_7078)\n        {\n            _7079 = _7074;\n        }\n        else\n        {\n            _7079 = length(_7068);\n        }\n        float _7091 = _7079 - fa_mesh_fs_params[8].x;\n        if (_7091 > 0.0)\n        {\n            float _7100 = fa_mesh_fs_params[7].w * _7091;\n            float tau = _7100 * _7100;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _7116;\n                if (_7078)\n                {\n                    _7116 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _7074);\n                }\n                else\n                {\n                    _7116 = fa_mesh_fs_params[0].y;\n                }\n                float _7137 = mix(_7116, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _7079, 0.0, 1.0));\n                float _7141 = fa_world_pos.y - _7137;\n                float _7146 = _7137 - fa_mesh_fs_params[8].z;\n                float _7151 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _7154 = _7146 <= 0.0;\n                bool _7155 = !_7154;\n                bool _7161;\n                if (_7155)\n                {\n                    _7161 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7161 = _7154;\n                }\n                float _7162;\n                if (_7161)\n                {\n                    _7162 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _7162 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _7146, 80.0));\n                }\n                bool _7189;\n                if (_7155)\n                {\n                    _7189 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7189 = _7154;\n                }\n                float _7190;\n                if (_7189)\n                {\n                    _7190 = fa_mesh_fs_params[8].y * _7146;\n                }\n                else\n                {\n                    _7190 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7146, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _7215 = _7151 <= 0.0;\n                bool _7222;\n                if (!_7215)\n                {\n                    _7222 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7222 = _7215;\n                }\n                float _7223;\n                if (_7222)\n                {\n                    _7223 = fa_mesh_fs_params[8].y * _7151;\n                }\n                else\n                {\n                    _7223 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7151, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _7250;\n                if (abs(_7141) < 0.001000000047497451305389404296875)\n                {\n                    _7250 = _7162;\n                }\n                else\n                {\n                    _7250 = (_7223 - _7190) / _7141;\n                }\n                tau += (_7091 * max(_7250, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _7348);\n}\n\n",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_517",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
            "inst_name": "_2169",
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
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_vel_params[9];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 9) in vec4 fa_prev_r0;\nlayout(location = 10) in vec4 fa_prev_r1;\nlayout(location = 11) in vec4 fa_prev_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _97 = cross(model[1].xyz, model[2].xyz);\n    float _101 = (dot(model[0].xyz, _97) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_97 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _101, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _101), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    return fa_rows_to_mat4(param, param_1, param_2);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _231;\n    if (has_prev)\n    {\n        _231 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _231 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _246 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _455 = _246.world_pos;\n    mat4 _250 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _257 = vec4(_455, 1.0);\n    fa_world_pos = _455;\n    fa_world_normal = _246.world_normal;\n    fa_world_tangent = _246.world_tangent;\n    fa_uv = _246.uv;\n    fa_vertex_color = _246.color;\n    fa_pre_depth = -(_250 * _257).z;\n    fa_pre_r0 = vec3(_250[0].x, _250[1].x, _250[2].x);\n    fa_pre_r1 = vec3(_250[0].y, _250[1].y, _250[2].y);\n    fa_pre_r2 = vec3(_250[0].z, _250[1].z, _250[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _257;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_231)\n    {\n        vec4 _330 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _257).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_455 + (fa_prev_model() * _330).xyz) - (model * _330).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    bool param_6 = true;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, param_6);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _230 = fa_tex_fix(param_2, param_3);\n    vec4 _889 = base_t;\n    _889.x = _230.x;\n    _889.y = _230.y;\n    _889.z = _230.z;\n    base_t = _889;\n    vec4 _246 = (_889 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _844 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _282 = fa_tex_fix(param_6, param_7);\n        vec3 _286 = (_282 * 2.0) - vec3(1.0);\n        vec2 _291 = _286.xy * fa_mesh_fs_params[6].x;\n        vec3 _897 = _286;\n        _897.x = _291.x;\n        _897.y = _291.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _897;\n        _844 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _322 = fa_tex_fix(param_12, param_13);\n    vec4 _900 = mrt;\n    _900.x = _322.x;\n    _900.y = _322.y;\n    _900.z = _322.z;\n    mrt = _900;\n    vec4 _354 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _849 = fa_mesh_fs_params[20].x;\n    float _850 = fa_mesh_fs_params[20].y;\n    float _853 = fa_mesh_fs_params[20].z;\n    float _852 = fa_mesh_fs_params[21].w;\n    float _855 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _849 *= _366.y;\n            _850 *= _366.z;\n            _852 *= _354.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _853 *= mrt.x;\n            _855 *= mrt.w;\n        }\n    }\n    return Surface(_246.xyz, _246.w, _844, clamp(fa_mesh_fs_params[5].x * _322.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_366.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _849, _850, fa_mesh_fs_params[21].xyz, _852, _853, fa_mesh_fs_params[20].w, _855, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _739 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _739 = -_739;\n    }\n    vec3 _550 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _565 = normalize(param_2.normal);\n    vec3 _580 = normalize(vec3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    vec2 e = _580.xy / vec2((abs(_580.x) + abs(_580.y)) + abs(_592));\n    if (_592 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "glsl_name": "fa_prev_r0"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r1"
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r2"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_57",
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
            "slot": 2,
            "stage": "vertex",
            "size": 144,
            "struct_name": "fa_vel_params",
            "inst_name": "_225",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 9,
                "offset": 0,
                "glsl_name": "fa_vel_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_214",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_vel_params[9];\nlayout(binding = 0) uniform sampler2D fa_prev_pal_tex_fa_prev_pal_smp;\n\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 11) in vec4 fa_prev_r0;\nlayout(location = 12) in vec4 fa_prev_r1;\nlayout(location = 13) in vec4 fa_prev_r2;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _204 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_204 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_204 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_204 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _113 = cross(model[1].xyz, model[2].xyz);\n    float _117 = (dot(model[0].xyz, _113) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_113 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _117, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _117), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_prev_pal_texel(int t)\n{\n    return texelFetch(fa_prev_pal_tex_fa_prev_pal_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nmat4 fa_prev_skin_matrix(vec4 joints, vec4 weights, int base)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _332 = base + (int((joints[i] * 255.0) + 0.5) * 3);\n        int param = _332;\n        r0 += (fa_prev_pal_texel(param) * weights[i]);\n        int param_1 = _332 + 1;\n        r1 += (fa_prev_pal_texel(param_1) * weights[i]);\n        int param_2 = _332 + 2;\n        r2 += (fa_prev_pal_texel(param_2) * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    vec4 param_3 = fa_joints;\n    vec4 param_4 = fa_weights;\n    int param_5 = int(fa_vel_params[8].w + 0.5);\n    return fa_rows_to_mat4(param, param_1, param_2) * fa_prev_skin_matrix(param_3, param_4, param_5);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _475;\n    if (has_prev)\n    {\n        _475 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _475 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _490 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _720 = _490.world_pos;\n    mat4 _494 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _501 = vec4(_720, 1.0);\n    fa_world_pos = _720;\n    fa_world_normal = _490.world_normal;\n    fa_world_tangent = _490.world_tangent;\n    fa_uv = _490.uv;\n    fa_vertex_color = _490.color;\n    fa_pre_depth = -(_494 * _501).z;\n    fa_pre_r0 = vec3(_494[0].x, _494[1].x, _494[2].x);\n    fa_pre_r1 = vec3(_494[0].y, _494[1].y, _494[2].y);\n    fa_pre_r2 = vec3(_494[0].z, _494[1].z, _494[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _501;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_475)\n    {\n        vec4 _574 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _501).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_720 + (fa_prev_model() * _574).xyz) - (model * _574).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    bool param_8 = fa_vel_params[8].z > 0.5;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _230 = fa_tex_fix(param_2, param_3);\n    vec4 _889 = base_t;\n    _889.x = _230.x;\n    _889.y = _230.y;\n    _889.z = _230.z;\n    base_t = _889;\n    vec4 _246 = (_889 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _844 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _282 = fa_tex_fix(param_6, param_7);\n        vec3 _286 = (_282 * 2.0) - vec3(1.0);\n        vec2 _291 = _286.xy * fa_mesh_fs_params[6].x;\n        vec3 _897 = _286;\n        _897.x = _291.x;\n        _897.y = _291.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _897;\n        _844 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _322 = fa_tex_fix(param_12, param_13);\n    vec4 _900 = mrt;\n    _900.x = _322.x;\n    _900.y = _322.y;\n    _900.z = _322.z;\n    mrt = _900;\n    vec4 _354 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _849 = fa_mesh_fs_params[20].x;\n    float _850 = fa_mesh_fs_params[20].y;\n    float _853 = fa_mesh_fs_params[20].z;\n    float _852 = fa_mesh_fs_params[21].w;\n    float _855 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _849 *= _366.y;\n            _850 *= _366.z;\n            _852 *= _354.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _853 *= mrt.x;\n            _855 *= mrt.w;\n        }\n    }\n    return Surface(_246.xyz, _246.w, _844, clamp(fa_mesh_fs_params[5].x * _322.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_366.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _849, _850, fa_mesh_fs_params[21].xyz, _852, _853, fa_mesh_fs_params[20].w, _855, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _739 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _739 = -_739;\n    }\n    vec3 _550 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _565 = normalize(param_2.normal);\n    vec3 _580 = normalize(vec3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    vec2 e = _580.xy / vec2((abs(_580.x) + abs(_580.y)) + abs(_592));\n    if (_592 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r0"
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r1"
          },
          {
            "slot": 13,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r2"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_74",
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
            "inst_name": "_213",
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
            "slot": 2,
            "stage": "vertex",
            "size": 144,
            "struct_name": "fa_vel_params",
            "inst_name": "_470",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 9,
                "offset": 0,
                "glsl_name": "fa_vel_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_214",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
          },
          {
            "texture": {
              "slot": 29,
              "stage": "vertex",
              "name": "fa_prev_pal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 11,
            "stage": "vertex",
            "name": "fa_prev_pal_smp",
            "sampler_type": "nonfiltering"
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
            "stage": "vertex",
            "name": "fa_prev_pal_tex_fa_prev_pal_smp",
            "view_name": "fa_prev_pal_tex",
            "sampler_name": "fa_prev_pal_smp",
            "view_slot": 29,
            "sampler_slot": 11,
            "glsl_name": "fa_prev_pal_tex_fa_prev_pal_smp"
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
          }
        ]
      }
    }
  }
}
