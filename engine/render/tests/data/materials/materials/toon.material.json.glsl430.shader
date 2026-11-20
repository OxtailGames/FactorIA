{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "738bdbaa5d236ca82c68b48e7af94b35c54ba5d6311eabf2bcbbc814ba3d221c",
  "slang": "glsl430",
  "params": [
    "dark"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _268 = _160.world_pos;\n    fa_world_pos = _268;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_268, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _704 = fa_mesh_fs_params[19].x < 0.0;\n    bool _711;\n    if (!_704)\n    {\n        _711 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _711 = _704;\n    }\n    bool _719;\n    if (!_711)\n    {\n        _719 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _719 = _711;\n    }\n    bool _726;\n    if (!_719)\n    {\n        _726 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _726 = _719;\n    }\n    bool _733;\n    if (!_726)\n    {\n        _733 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _733 = _726;\n    }\n    if (_733)\n    {\n        return ivec2(0);\n    }\n    vec4 _743 = vec4(world_pos, 1.0);\n    float _750 = dot(fa_mesh_fs_params[16], _743);\n    if (!(_750 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _772 = vec2(dot(fa_mesh_fs_params[14], _743), dot(fa_mesh_fs_params[15], _743)) / vec2(_750);\n    int _776 = int(fa_mesh_fs_params[18].x);\n    int _780 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _780) + clamp(int(floor(((_772.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _780 - 1)) * _776)) + clamp(int(floor(((_772.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _776 - 1);\n    vec4 _851 = fa_light_texel(param);\n    return ivec2(int(_851.x), int(_851.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _1593 = fa_cluster_lookup(param);\n    fa_cl_slot = _1593.x;\n    fa_cl_local = _1593.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1722 = fa_linear_to_srgb(param);\n        c = _1722;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1730 = fa_srgb_to_linear(param_1);\n            c = _1730;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _164;\n    if (i.front_facing)\n    {\n        _164 = i.world_normal;\n    }\n    else\n    {\n        _164 = -i.world_normal;\n    }\n    vec3 _188 = normalize(i.world_tangent.xyz - (_164 * dot(_164, i.world_tangent.xyz)));\n    vec3 _216 = normalize(((_188 * m.x) + ((cross(_164, _188) * i.world_tangent.w) * m.y)) + (_164 * m.z));\n    vec3 _219;\n    if (i.front_facing)\n    {\n        _219 = _216;\n    }\n    else\n    {\n        _219 = -_216;\n    }\n    return _219;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1761 = fa_tex_fix(param_2, param_3);\n    vec4 _2656 = base_t;\n    _2656.x = _1761.x;\n    _2656.y = _1761.y;\n    _2656.z = _1761.z;\n    base_t = _2656;\n    vec4 _1775 = (_2656 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2593 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1807 = fa_tex_fix(param_6, param_7);\n        vec3 _1811 = (_1807 * 2.0) - vec3(1.0);\n        vec2 _1816 = _1811.xy * fa_mesh_fs_params[6].x;\n        vec3 _2664 = _1811;\n        _2664.x = _1816.x;\n        _2664.y = _1816.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2664;\n        _2593 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1844 = fa_tex_fix(param_12, param_13);\n    vec4 _2667 = mrt;\n    _2667.x = _1844.x;\n    _2667.y = _1844.y;\n    _2667.z = _1844.z;\n    mrt = _2667;\n    vec4 _1873 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _1873.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1885 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _1915 = fa_tex_fix(param_20, param_21);\n    float _2598 = fa_mesh_fs_params[20].x;\n    float _2599 = fa_mesh_fs_params[20].y;\n    float _2602 = fa_mesh_fs_params[20].z;\n    float _2601 = fa_mesh_fs_params[21].w;\n    float _2604 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _2598 *= _1885.y;\n            _2599 *= _1885.z;\n            _2601 *= _1873.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _2602 *= mrt.x;\n            _2604 *= mrt.w;\n        }\n    }\n    return Surface(_1775.xyz, _1775.w, _2593, clamp(fa_mesh_fs_params[5].x * _1844.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1844.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1885.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _1915), _2598, _2599, fa_mesh_fs_params[21].xyz, _2601, _2602, fa_mesh_fs_params[20].w, _2604, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[10].y > 4.5) ? 8 : 4);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _313 = dot(d, right);\n    float _317 = dot(d, up);\n    float _328;\n    if (((_313 * _313) + (_317 * _317)) > 1.0000000133514319600180897396058e-10)\n    {\n        _328 = atan(_317, _313) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _328 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_328 - floor(_328)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li;\n    int _361 = fa_light_base(param);\n    bool _365 = fa_mesh_fs_params[10].y > 4.5;\n    int param_1 = _361;\n    vec4 _369 = fa_light_texel(param_1);\n    int param_2 = _361 + 1;\n    vec4 _374 = fa_light_texel(param_2);\n    float _377 = _374.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _389 = _365 && (_377 > 2.5);\n    fa_light_is_area = _389;\n    bool _392 = _377 < 0.5;\n    vec3 l;\n    if (_392)\n    {\n        l = normalize(_369.xyz);\n        if (_365)\n        {\n            int param_3 = _361 + 6;\n            vec4 _406 = fa_light_texel(param_3);\n            if (_406.z > 0.5)\n            {\n                int param_4 = _361 + 4;\n                vec4 _416 = fa_light_texel(param_4);\n                int param_5 = _361 + 5;\n                vec4 _422 = fa_light_texel(param_5);\n                vec2 param_6 = _406.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _416.xyz) * _416.w, (-dot(world_pos, _422.xyz)) * _422.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _454 = _369.xyz - world_pos;\n        float _456 = length(_454);\n        dist = _456;\n        l = _454 / vec3(max(_456, 9.9999997473787516355514526367188e-05));\n        float reach = _456;\n        if (_389)\n        {\n            int param_8 = _361 + 7;\n            reach = max(dist - fa_light_texel(param_8).w, 0.0);\n        }\n        float _488 = reach / max(_369.w, 0.001000000047497451305389404296875);\n        float _494 = clamp(1.0 - (_488 * _488), 0.0, 1.0);\n        atten = _494 * _494;\n        bool _502 = _377 < 2.5;\n        if ((_377 > 1.5) && _502)\n        {\n            int param_9 = _361 + 2;\n            vec4 _510 = fa_light_texel(param_9);\n            float _520 = _510.w;\n            int param_10 = _361 + 3;\n            vec4 _526 = fa_light_texel(param_10);\n            float _527 = _526.x;\n            float cos_inner = _527;\n            if (_527 > 1.5)\n            {\n                cos_inner = mix(_520, 1.0, 0.25);\n            }\n            atten *= smoothstep(_520, cos_inner, dot(-l, normalize(_510.xyz)));\n        }\n        if (_365 && _502)\n        {\n            int param_11 = _361 + 6;\n            vec4 _551 = fa_light_texel(param_11);\n            int param_12 = _361 + 7;\n            vec4 _556 = fa_light_texel(param_12);\n            bool _559 = _551.z > 0.5;\n            bool _566;\n            if (!_559)\n            {\n                _566 = _556.z > 0.5;\n            }\n            else\n            {\n                _566 = _559;\n            }\n            if (_566)\n            {\n                int param_13 = _361 + 2;\n                vec4 _573 = fa_light_texel(param_13);\n                vec3 _577 = normalize(_573.xyz);\n                int param_14 = _361 + 4;\n                vec4 _582 = fa_light_texel(param_14);\n                int param_15 = _361 + 5;\n                vec4 _587 = fa_light_texel(param_15);\n                if (_559)\n                {\n                    vec3 _595 = -_454;\n                    float _602 = _573.w;\n                    float _618 = 0.5 / max(dot(_595, _577) * (sqrt(max(1.0 - (_602 * _602), 0.0)) / max(_602, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                    vec2 param_16 = _551.xy;\n                    vec2 param_17 = vec2(0.5 + (dot(_595, _582.xyz) * _618), 0.5 - (dot(_595, _587.xyz) * _618));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17);\n                }\n                if (_556.z > 0.5)\n                {\n                    vec2 param_18 = _556.xy;\n                    vec3 param_19 = -l;\n                    vec3 param_20 = _577;\n                    vec3 param_21 = _582.xyz;\n                    vec3 param_22 = _587.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22);\n                }\n            }\n        }\n    }\n    vec3 _2560 = _374.xyz * atten;\n    if (_365)\n    {\n        _2560 *= fa_light_tint;\n    }\n    int _686;\n    if (_392)\n    {\n        _686 = 0;\n    }\n    else\n    {\n        _686 = ((_377 > 1.5) && (_377 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _2560, atten, 1.0, dist, _686);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _925;\n    if (i == 0)\n    {\n        _925 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _941;\n        if (i == 1)\n        {\n            _941 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _949;\n            if (i == 2)\n            {\n                _949 = fa_shadows[24].z;\n            }\n            else\n            {\n                _949 = fa_shadows[24].w;\n            }\n            _941 = _949;\n        }\n        _925 = _941;\n    }\n    return _925;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _913 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_913), sin(_913)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _987 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _992 = clamp(dot(n, l), 0.0, 1.0);\n    float _998 = sqrt(1.0 - (_992 * _992));\n    float _1006 = min(_998 / max(_992, 0.20000000298023223876953125), 4.0);\n    float _1011;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1011 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1011 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1036 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1011 * _998)), 1.0);\n    float _1043 = _1036.x;\n    bool _1046 = _1043 < fa_shadows[ci * 1 + 16].x;\n    bool _1055;\n    if (!_1046)\n    {\n        _1055 = _1043 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1055 = _1046;\n    }\n    bool _1064;\n    if (!_1055)\n    {\n        _1064 = _1036.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1064 = _1055;\n    }\n    bool _1073;\n    if (!_1064)\n    {\n        _1073 = _1036.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1073 = _1064;\n    }\n    bool _1080;\n    if (!_1073)\n    {\n        _1080 = _1036.z > 1.0;\n    }\n    else\n    {\n        _1080 = _1073;\n    }\n    if (_1080)\n    {\n        return -1.0;\n    }\n    float _1088;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1088 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1088 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _1107 = _1036.z - ((_1088 * (1.0 + (0.5 * _1006))) / _987);\n    float _1116 = ((fa_shadows[ci * 1 + 20].x * min(_1006, 3.0)) * 0.5) / _987;\n    int _1125 = int(fa_shadows[25].z + 0.5);\n    if (_1125 == 1)\n    {\n        vec2 param = _1036.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _1136 = fa_shadow_depth(param, param_1);\n        return float(_1107 <= _1136);\n    }\n    float _1143 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1146 = _1125 == 2;\n    if (_1146)\n    {\n        float _1160 = clamp(((fa_shadows[25].w * _987) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1143;\n            vec2 _1179 = fa_shadow_vogel(param_2, param_3, param_4) * _1160;\n            vec2 param_5 = _1036.xy + (_1179 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _1190 = fa_shadow_depth(param_5, param_6);\n            if (_1190 < (_1107 - (length(_1179) * _1116)))\n            {\n                sum += _1190;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_1107 - (sum / cnt), 0.0) * _987) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1234 = _1146 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1234; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1234;\n        float param_9 = _1143;\n        vec2 _1253 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _1036.xy + (_1253 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1264 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1107 - (length(_1253) * _1116)) <= _1264);\n    }\n    return lit / float(_1234);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1294 = int(fa_shadows[25].x + 0.5);\n    if (_1294 < 1)\n    {\n        return 1.0;\n    }\n    float _1309 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1294 - 1;\n    if (_1309 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1321 = _1294 > 1;\n    bool _1328;\n    if (_1321)\n    {\n        _1328 = _1309 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1328 = _1321;\n    }\n    if (_1328)\n    {\n        ci = 1;\n    }\n    bool _1332 = _1294 > 2;\n    bool _1339;\n    if (_1332)\n    {\n        _1339 = _1309 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1339 = _1332;\n    }\n    if (_1339)\n    {\n        ci = 2;\n    }\n    bool _1343 = _1294 > 3;\n    bool _1350;\n    if (_1343)\n    {\n        _1350 = _1309 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1350 = _1343;\n    }\n    if (_1350)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1294)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1376 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1376;\n        if (_1376 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1401;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1401 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1401 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1420 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1401, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1431 = clamp((_1309 - (fa_shadow_split_at(param_7) - _1420)) / _1420, 0.0, 1.0);\n        if (_1431 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1294)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1452 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1452;\n                if (_1452 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1431);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1621 = fa_light_sample(param, param_1);\n    vec3 _2573 = _1621.color;\n    float _2575 = _1621.shadow;\n    if ((_1621.type == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _1621.direction;\n        float _1635 = fa_shadow_factor(param_2, param_3);\n        _2575 = _1635;\n        _2573 *= _1635;\n    }\n    return LightSample(_1621.direction, _2573, _1621.attenuation, _2575, _1621._distance, _1621.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _1655;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _1655 = 1.0;\n    }\n    else\n    {\n        _1655 = fa_material[0].x;\n    }\n    return (s.albedo * l.color) * _1655;\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1476 = int(fa_shadows[25].x + 0.5);\n    float _1486 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1491 = _1476 > 0;\n    bool _1500;\n    if (_1491)\n    {\n        int param = _1476 - 1;\n        _1500 = _1486 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1500 = _1491;\n    }\n    if (_1500)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1507 = _1476 > 1;\n        bool _1514;\n        if (_1507)\n        {\n            _1514 = _1486 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1514 = _1507;\n        }\n        if (_1514)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1520 = _1476 > 2;\n        bool _1527;\n        if (_1520)\n        {\n            _1527 = _1486 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1527 = _1520;\n        }\n        if (_1527)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1533 = _1476 > 3;\n        bool _1540;\n        if (_1533)\n        {\n            _1540 = _1486 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1540 = _1533;\n        }\n        if (_1540)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2427 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2427 = -_2427;\n    }\n    vec3 _2040 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2427, fa_world_tangent, fa_uv, fa_vertex_color, _2040, gl_FrontFacing);\n    Surface _2048 = fa_standard_surface(param_1);\n    vec3 _2458 = _2048.albedo;\n    float _2459 = _2048.alpha;\n    vec3 _2460 = _2048.normal;\n    float _2461 = _2048.metallic;\n    float _2462 = _2048.roughness;\n    float _2463 = _2048.occlusion;\n    vec3 _2464 = _2048.emission;\n    float _2465 = _2048.clearcoat;\n    float _2466 = _2048.clearcoat_roughness;\n    vec3 _2467 = _2048.sheen_color;\n    float _2468 = _2048.sheen_roughness;\n    float _2469 = _2048.anisotropy;\n    float _2470 = _2048.anisotropy_rotation;\n    float _2471 = _2048.specular;\n    float _2472 = _2048.ior;\n    vec3 _2473 = _2048.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2427, fa_world_tangent, fa_uv, fa_vertex_color, _2040, gl_FrontFacing);\n    Surface param_3 = _2048;\n    surface(param_2, param_3);\n    _2458 = param_3.albedo;\n    _2459 = param_3.alpha;\n    _2460 = param_3.normal;\n    _2461 = param_3.metallic;\n    _2462 = param_3.roughness;\n    _2463 = param_3.occlusion;\n    _2464 = param_3.emission;\n    _2465 = param_3.clearcoat;\n    _2466 = param_3.clearcoat_roughness;\n    _2467 = param_3.sheen_color;\n    _2468 = param_3.sheen_roughness;\n    _2469 = param_3.anisotropy;\n    _2470 = param_3.anisotropy_rotation;\n    _2471 = param_3.specular;\n    _2472 = param_3.ior;\n    _2473 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2458;\n    }\n    else\n    {\n        vec3 _2069 = _2460;\n        vec3 _2070 = normalize(_2069);\n        _2460 = _2070;\n        vec3 param_4 = _2070;\n        vec3 lit = (fa_ambient_light(param_4) * _2458) * _2463;\n        int _2089 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2089; ln++)\n        {\n            int param_5 = ln;\n            int param_6 = fa_cl_light(param_5);\n            vec3 param_7 = fa_world_pos;\n            vec3 param_8 = _2427;\n            LightSample _2111 = fa_light_shadowed(param_6, param_7, param_8);\n            SurfaceInput param_9 = SurfaceInput(fa_world_pos, _2427, fa_world_tangent, fa_uv, fa_vertex_color, _2040, gl_FrontFacing);\n            Surface param_10 = Surface(_2458, _2459, _2460, _2461, _2462, _2463, _2464, _2465, _2466, _2467, _2468, _2469, _2470, _2471, _2472, _2473);\n            LightSample param_11 = _2111;\n            lit += light(param_9, param_10, param_11);\n        }\n        result = lit;\n    }\n    vec3 _2126 = result;\n    vec3 _2127 = _2126 + _2464;\n    result = _2127;\n    vec3 param_12 = _2127;\n    vec3 param_13 = fa_world_pos;\n    result = fa_shadow_debug(param_12, param_13);\n    bool _2136 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2143;\n    if (!_2136)\n    {\n        _2143 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2143 = _2136;\n    }\n    if (_2143)\n    {\n        vec3 _2152 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2158 = dot(_2152, fa_mesh_fs_params[9].xyz);\n        bool _2162 = fa_mesh_fs_params[9].w > 0.5;\n        float _2163;\n        if (_2162)\n        {\n            _2163 = _2158;\n        }\n        else\n        {\n            _2163 = length(_2152);\n        }\n        float _2175 = _2163 - fa_mesh_fs_params[8].x;\n        if (_2175 > 0.0)\n        {\n            float _2184 = fa_mesh_fs_params[7].w * _2175;\n            float tau = _2184 * _2184;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2200;\n                if (_2162)\n                {\n                    _2200 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2158);\n                }\n                else\n                {\n                    _2200 = fa_mesh_fs_params[0].y;\n                }\n                float _2221 = mix(_2200, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2163, 0.0, 1.0));\n                float _2225 = fa_world_pos.y - _2221;\n                float _2230 = _2221 - fa_mesh_fs_params[8].z;\n                float _2235 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2238 = _2230 <= 0.0;\n                bool _2239 = !_2238;\n                bool _2245;\n                if (_2239)\n                {\n                    _2245 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2245 = _2238;\n                }\n                float _2246;\n                if (_2245)\n                {\n                    _2246 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2246 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2230, 80.0));\n                }\n                bool _2273;\n                if (_2239)\n                {\n                    _2273 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2273 = _2238;\n                }\n                float _2274;\n                if (_2273)\n                {\n                    _2274 = fa_mesh_fs_params[8].y * _2230;\n                }\n                else\n                {\n                    _2274 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2230, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2299 = _2235 <= 0.0;\n                bool _2306;\n                if (!_2299)\n                {\n                    _2306 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2306 = _2299;\n                }\n                float _2307;\n                if (_2306)\n                {\n                    _2307 = fa_mesh_fs_params[8].y * _2235;\n                }\n                else\n                {\n                    _2307 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2235, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2334;\n                if (abs(_2225) < 0.001000000047497451305389404296875)\n                {\n                    _2334 = _2246;\n                }\n                else\n                {\n                    _2334 = (_2307 - _2274) / _2225;\n                }\n                tau += (_2175 * max(_2334, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2459);\n}\n\n",
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
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 10,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_232",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 24,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_935",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 29,
                "offset": 0,
                "glsl_name": "fa_shadows"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1661",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10,
            "glsl_name": "fa_irr_tex_fa_env_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
          },
          {
            "slot": 8,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _389 = _273.world_pos;\n    fa_world_pos = _389;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_389, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _704 = fa_mesh_fs_params[19].x < 0.0;\n    bool _711;\n    if (!_704)\n    {\n        _711 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _711 = _704;\n    }\n    bool _719;\n    if (!_711)\n    {\n        _719 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _719 = _711;\n    }\n    bool _726;\n    if (!_719)\n    {\n        _726 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _726 = _719;\n    }\n    bool _733;\n    if (!_726)\n    {\n        _733 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _733 = _726;\n    }\n    if (_733)\n    {\n        return ivec2(0);\n    }\n    vec4 _743 = vec4(world_pos, 1.0);\n    float _750 = dot(fa_mesh_fs_params[16], _743);\n    if (!(_750 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _772 = vec2(dot(fa_mesh_fs_params[14], _743), dot(fa_mesh_fs_params[15], _743)) / vec2(_750);\n    int _776 = int(fa_mesh_fs_params[18].x);\n    int _780 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _780) + clamp(int(floor(((_772.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _780 - 1)) * _776)) + clamp(int(floor(((_772.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _776 - 1);\n    vec4 _851 = fa_light_texel(param);\n    return ivec2(int(_851.x), int(_851.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _1593 = fa_cluster_lookup(param);\n    fa_cl_slot = _1593.x;\n    fa_cl_local = _1593.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1722 = fa_linear_to_srgb(param);\n        c = _1722;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1730 = fa_srgb_to_linear(param_1);\n            c = _1730;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _164;\n    if (i.front_facing)\n    {\n        _164 = i.world_normal;\n    }\n    else\n    {\n        _164 = -i.world_normal;\n    }\n    vec3 _188 = normalize(i.world_tangent.xyz - (_164 * dot(_164, i.world_tangent.xyz)));\n    vec3 _216 = normalize(((_188 * m.x) + ((cross(_164, _188) * i.world_tangent.w) * m.y)) + (_164 * m.z));\n    vec3 _219;\n    if (i.front_facing)\n    {\n        _219 = _216;\n    }\n    else\n    {\n        _219 = -_216;\n    }\n    return _219;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1761 = fa_tex_fix(param_2, param_3);\n    vec4 _2656 = base_t;\n    _2656.x = _1761.x;\n    _2656.y = _1761.y;\n    _2656.z = _1761.z;\n    base_t = _2656;\n    vec4 _1775 = (_2656 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2593 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1807 = fa_tex_fix(param_6, param_7);\n        vec3 _1811 = (_1807 * 2.0) - vec3(1.0);\n        vec2 _1816 = _1811.xy * fa_mesh_fs_params[6].x;\n        vec3 _2664 = _1811;\n        _2664.x = _1816.x;\n        _2664.y = _1816.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2664;\n        _2593 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1844 = fa_tex_fix(param_12, param_13);\n    vec4 _2667 = mrt;\n    _2667.x = _1844.x;\n    _2667.y = _1844.y;\n    _2667.z = _1844.z;\n    mrt = _2667;\n    vec4 _1873 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _1873.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1885 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _1915 = fa_tex_fix(param_20, param_21);\n    float _2598 = fa_mesh_fs_params[20].x;\n    float _2599 = fa_mesh_fs_params[20].y;\n    float _2602 = fa_mesh_fs_params[20].z;\n    float _2601 = fa_mesh_fs_params[21].w;\n    float _2604 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _2598 *= _1885.y;\n            _2599 *= _1885.z;\n            _2601 *= _1873.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _2602 *= mrt.x;\n            _2604 *= mrt.w;\n        }\n    }\n    return Surface(_1775.xyz, _1775.w, _2593, clamp(fa_mesh_fs_params[5].x * _1844.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1844.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1885.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _1915), _2598, _2599, fa_mesh_fs_params[21].xyz, _2601, _2602, fa_mesh_fs_params[20].w, _2604, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[10].y > 4.5) ? 8 : 4);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _313 = dot(d, right);\n    float _317 = dot(d, up);\n    float _328;\n    if (((_313 * _313) + (_317 * _317)) > 1.0000000133514319600180897396058e-10)\n    {\n        _328 = atan(_317, _313) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _328 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_328 - floor(_328)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li;\n    int _361 = fa_light_base(param);\n    bool _365 = fa_mesh_fs_params[10].y > 4.5;\n    int param_1 = _361;\n    vec4 _369 = fa_light_texel(param_1);\n    int param_2 = _361 + 1;\n    vec4 _374 = fa_light_texel(param_2);\n    float _377 = _374.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _389 = _365 && (_377 > 2.5);\n    fa_light_is_area = _389;\n    bool _392 = _377 < 0.5;\n    vec3 l;\n    if (_392)\n    {\n        l = normalize(_369.xyz);\n        if (_365)\n        {\n            int param_3 = _361 + 6;\n            vec4 _406 = fa_light_texel(param_3);\n            if (_406.z > 0.5)\n            {\n                int param_4 = _361 + 4;\n                vec4 _416 = fa_light_texel(param_4);\n                int param_5 = _361 + 5;\n                vec4 _422 = fa_light_texel(param_5);\n                vec2 param_6 = _406.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _416.xyz) * _416.w, (-dot(world_pos, _422.xyz)) * _422.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _454 = _369.xyz - world_pos;\n        float _456 = length(_454);\n        dist = _456;\n        l = _454 / vec3(max(_456, 9.9999997473787516355514526367188e-05));\n        float reach = _456;\n        if (_389)\n        {\n            int param_8 = _361 + 7;\n            reach = max(dist - fa_light_texel(param_8).w, 0.0);\n        }\n        float _488 = reach / max(_369.w, 0.001000000047497451305389404296875);\n        float _494 = clamp(1.0 - (_488 * _488), 0.0, 1.0);\n        atten = _494 * _494;\n        bool _502 = _377 < 2.5;\n        if ((_377 > 1.5) && _502)\n        {\n            int param_9 = _361 + 2;\n            vec4 _510 = fa_light_texel(param_9);\n            float _520 = _510.w;\n            int param_10 = _361 + 3;\n            vec4 _526 = fa_light_texel(param_10);\n            float _527 = _526.x;\n            float cos_inner = _527;\n            if (_527 > 1.5)\n            {\n                cos_inner = mix(_520, 1.0, 0.25);\n            }\n            atten *= smoothstep(_520, cos_inner, dot(-l, normalize(_510.xyz)));\n        }\n        if (_365 && _502)\n        {\n            int param_11 = _361 + 6;\n            vec4 _551 = fa_light_texel(param_11);\n            int param_12 = _361 + 7;\n            vec4 _556 = fa_light_texel(param_12);\n            bool _559 = _551.z > 0.5;\n            bool _566;\n            if (!_559)\n            {\n                _566 = _556.z > 0.5;\n            }\n            else\n            {\n                _566 = _559;\n            }\n            if (_566)\n            {\n                int param_13 = _361 + 2;\n                vec4 _573 = fa_light_texel(param_13);\n                vec3 _577 = normalize(_573.xyz);\n                int param_14 = _361 + 4;\n                vec4 _582 = fa_light_texel(param_14);\n                int param_15 = _361 + 5;\n                vec4 _587 = fa_light_texel(param_15);\n                if (_559)\n                {\n                    vec3 _595 = -_454;\n                    float _602 = _573.w;\n                    float _618 = 0.5 / max(dot(_595, _577) * (sqrt(max(1.0 - (_602 * _602), 0.0)) / max(_602, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                    vec2 param_16 = _551.xy;\n                    vec2 param_17 = vec2(0.5 + (dot(_595, _582.xyz) * _618), 0.5 - (dot(_595, _587.xyz) * _618));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17);\n                }\n                if (_556.z > 0.5)\n                {\n                    vec2 param_18 = _556.xy;\n                    vec3 param_19 = -l;\n                    vec3 param_20 = _577;\n                    vec3 param_21 = _582.xyz;\n                    vec3 param_22 = _587.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22);\n                }\n            }\n        }\n    }\n    vec3 _2560 = _374.xyz * atten;\n    if (_365)\n    {\n        _2560 *= fa_light_tint;\n    }\n    int _686;\n    if (_392)\n    {\n        _686 = 0;\n    }\n    else\n    {\n        _686 = ((_377 > 1.5) && (_377 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _2560, atten, 1.0, dist, _686);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _925;\n    if (i == 0)\n    {\n        _925 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _941;\n        if (i == 1)\n        {\n            _941 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _949;\n            if (i == 2)\n            {\n                _949 = fa_shadows[24].z;\n            }\n            else\n            {\n                _949 = fa_shadows[24].w;\n            }\n            _941 = _949;\n        }\n        _925 = _941;\n    }\n    return _925;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _913 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_913), sin(_913)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _987 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _992 = clamp(dot(n, l), 0.0, 1.0);\n    float _998 = sqrt(1.0 - (_992 * _992));\n    float _1006 = min(_998 / max(_992, 0.20000000298023223876953125), 4.0);\n    float _1011;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1011 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1011 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1036 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1011 * _998)), 1.0);\n    float _1043 = _1036.x;\n    bool _1046 = _1043 < fa_shadows[ci * 1 + 16].x;\n    bool _1055;\n    if (!_1046)\n    {\n        _1055 = _1043 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1055 = _1046;\n    }\n    bool _1064;\n    if (!_1055)\n    {\n        _1064 = _1036.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1064 = _1055;\n    }\n    bool _1073;\n    if (!_1064)\n    {\n        _1073 = _1036.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1073 = _1064;\n    }\n    bool _1080;\n    if (!_1073)\n    {\n        _1080 = _1036.z > 1.0;\n    }\n    else\n    {\n        _1080 = _1073;\n    }\n    if (_1080)\n    {\n        return -1.0;\n    }\n    float _1088;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1088 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1088 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _1107 = _1036.z - ((_1088 * (1.0 + (0.5 * _1006))) / _987);\n    float _1116 = ((fa_shadows[ci * 1 + 20].x * min(_1006, 3.0)) * 0.5) / _987;\n    int _1125 = int(fa_shadows[25].z + 0.5);\n    if (_1125 == 1)\n    {\n        vec2 param = _1036.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _1136 = fa_shadow_depth(param, param_1);\n        return float(_1107 <= _1136);\n    }\n    float _1143 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1146 = _1125 == 2;\n    if (_1146)\n    {\n        float _1160 = clamp(((fa_shadows[25].w * _987) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1143;\n            vec2 _1179 = fa_shadow_vogel(param_2, param_3, param_4) * _1160;\n            vec2 param_5 = _1036.xy + (_1179 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _1190 = fa_shadow_depth(param_5, param_6);\n            if (_1190 < (_1107 - (length(_1179) * _1116)))\n            {\n                sum += _1190;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_1107 - (sum / cnt), 0.0) * _987) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1234 = _1146 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1234; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1234;\n        float param_9 = _1143;\n        vec2 _1253 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _1036.xy + (_1253 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1264 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1107 - (length(_1253) * _1116)) <= _1264);\n    }\n    return lit / float(_1234);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1294 = int(fa_shadows[25].x + 0.5);\n    if (_1294 < 1)\n    {\n        return 1.0;\n    }\n    float _1309 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1294 - 1;\n    if (_1309 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1321 = _1294 > 1;\n    bool _1328;\n    if (_1321)\n    {\n        _1328 = _1309 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1328 = _1321;\n    }\n    if (_1328)\n    {\n        ci = 1;\n    }\n    bool _1332 = _1294 > 2;\n    bool _1339;\n    if (_1332)\n    {\n        _1339 = _1309 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1339 = _1332;\n    }\n    if (_1339)\n    {\n        ci = 2;\n    }\n    bool _1343 = _1294 > 3;\n    bool _1350;\n    if (_1343)\n    {\n        _1350 = _1309 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1350 = _1343;\n    }\n    if (_1350)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1294)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1376 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1376;\n        if (_1376 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1401;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1401 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1401 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1420 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1401, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1431 = clamp((_1309 - (fa_shadow_split_at(param_7) - _1420)) / _1420, 0.0, 1.0);\n        if (_1431 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1294)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1452 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1452;\n                if (_1452 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1431);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1621 = fa_light_sample(param, param_1);\n    vec3 _2573 = _1621.color;\n    float _2575 = _1621.shadow;\n    if ((_1621.type == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _1621.direction;\n        float _1635 = fa_shadow_factor(param_2, param_3);\n        _2575 = _1635;\n        _2573 *= _1635;\n    }\n    return LightSample(_1621.direction, _2573, _1621.attenuation, _2575, _1621._distance, _1621.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _1655;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _1655 = 1.0;\n    }\n    else\n    {\n        _1655 = fa_material[0].x;\n    }\n    return (s.albedo * l.color) * _1655;\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1476 = int(fa_shadows[25].x + 0.5);\n    float _1486 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1491 = _1476 > 0;\n    bool _1500;\n    if (_1491)\n    {\n        int param = _1476 - 1;\n        _1500 = _1486 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1500 = _1491;\n    }\n    if (_1500)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1507 = _1476 > 1;\n        bool _1514;\n        if (_1507)\n        {\n            _1514 = _1486 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1514 = _1507;\n        }\n        if (_1514)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1520 = _1476 > 2;\n        bool _1527;\n        if (_1520)\n        {\n            _1527 = _1486 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1527 = _1520;\n        }\n        if (_1527)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1533 = _1476 > 3;\n        bool _1540;\n        if (_1533)\n        {\n            _1540 = _1486 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1540 = _1533;\n        }\n        if (_1540)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2427 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2427 = -_2427;\n    }\n    vec3 _2040 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2427, fa_world_tangent, fa_uv, fa_vertex_color, _2040, gl_FrontFacing);\n    Surface _2048 = fa_standard_surface(param_1);\n    vec3 _2458 = _2048.albedo;\n    float _2459 = _2048.alpha;\n    vec3 _2460 = _2048.normal;\n    float _2461 = _2048.metallic;\n    float _2462 = _2048.roughness;\n    float _2463 = _2048.occlusion;\n    vec3 _2464 = _2048.emission;\n    float _2465 = _2048.clearcoat;\n    float _2466 = _2048.clearcoat_roughness;\n    vec3 _2467 = _2048.sheen_color;\n    float _2468 = _2048.sheen_roughness;\n    float _2469 = _2048.anisotropy;\n    float _2470 = _2048.anisotropy_rotation;\n    float _2471 = _2048.specular;\n    float _2472 = _2048.ior;\n    vec3 _2473 = _2048.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2427, fa_world_tangent, fa_uv, fa_vertex_color, _2040, gl_FrontFacing);\n    Surface param_3 = _2048;\n    surface(param_2, param_3);\n    _2458 = param_3.albedo;\n    _2459 = param_3.alpha;\n    _2460 = param_3.normal;\n    _2461 = param_3.metallic;\n    _2462 = param_3.roughness;\n    _2463 = param_3.occlusion;\n    _2464 = param_3.emission;\n    _2465 = param_3.clearcoat;\n    _2466 = param_3.clearcoat_roughness;\n    _2467 = param_3.sheen_color;\n    _2468 = param_3.sheen_roughness;\n    _2469 = param_3.anisotropy;\n    _2470 = param_3.anisotropy_rotation;\n    _2471 = param_3.specular;\n    _2472 = param_3.ior;\n    _2473 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2458;\n    }\n    else\n    {\n        vec3 _2069 = _2460;\n        vec3 _2070 = normalize(_2069);\n        _2460 = _2070;\n        vec3 param_4 = _2070;\n        vec3 lit = (fa_ambient_light(param_4) * _2458) * _2463;\n        int _2089 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2089; ln++)\n        {\n            int param_5 = ln;\n            int param_6 = fa_cl_light(param_5);\n            vec3 param_7 = fa_world_pos;\n            vec3 param_8 = _2427;\n            LightSample _2111 = fa_light_shadowed(param_6, param_7, param_8);\n            SurfaceInput param_9 = SurfaceInput(fa_world_pos, _2427, fa_world_tangent, fa_uv, fa_vertex_color, _2040, gl_FrontFacing);\n            Surface param_10 = Surface(_2458, _2459, _2460, _2461, _2462, _2463, _2464, _2465, _2466, _2467, _2468, _2469, _2470, _2471, _2472, _2473);\n            LightSample param_11 = _2111;\n            lit += light(param_9, param_10, param_11);\n        }\n        result = lit;\n    }\n    vec3 _2126 = result;\n    vec3 _2127 = _2126 + _2464;\n    result = _2127;\n    vec3 param_12 = _2127;\n    vec3 param_13 = fa_world_pos;\n    result = fa_shadow_debug(param_12, param_13);\n    bool _2136 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2143;\n    if (!_2136)\n    {\n        _2143 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2143 = _2136;\n    }\n    if (_2143)\n    {\n        vec3 _2152 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2158 = dot(_2152, fa_mesh_fs_params[9].xyz);\n        bool _2162 = fa_mesh_fs_params[9].w > 0.5;\n        float _2163;\n        if (_2162)\n        {\n            _2163 = _2158;\n        }\n        else\n        {\n            _2163 = length(_2152);\n        }\n        float _2175 = _2163 - fa_mesh_fs_params[8].x;\n        if (_2175 > 0.0)\n        {\n            float _2184 = fa_mesh_fs_params[7].w * _2175;\n            float tau = _2184 * _2184;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2200;\n                if (_2162)\n                {\n                    _2200 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2158);\n                }\n                else\n                {\n                    _2200 = fa_mesh_fs_params[0].y;\n                }\n                float _2221 = mix(_2200, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2163, 0.0, 1.0));\n                float _2225 = fa_world_pos.y - _2221;\n                float _2230 = _2221 - fa_mesh_fs_params[8].z;\n                float _2235 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2238 = _2230 <= 0.0;\n                bool _2239 = !_2238;\n                bool _2245;\n                if (_2239)\n                {\n                    _2245 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2245 = _2238;\n                }\n                float _2246;\n                if (_2245)\n                {\n                    _2246 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2246 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2230, 80.0));\n                }\n                bool _2273;\n                if (_2239)\n                {\n                    _2273 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2273 = _2238;\n                }\n                float _2274;\n                if (_2273)\n                {\n                    _2274 = fa_mesh_fs_params[8].y * _2230;\n                }\n                else\n                {\n                    _2274 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2230, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2299 = _2235 <= 0.0;\n                bool _2306;\n                if (!_2299)\n                {\n                    _2306 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2306 = _2299;\n                }\n                float _2307;\n                if (_2306)\n                {\n                    _2307 = fa_mesh_fs_params[8].y * _2235;\n                }\n                else\n                {\n                    _2307 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2235, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2334;\n                if (abs(_2225) < 0.001000000047497451305389404296875)\n                {\n                    _2334 = _2246;\n                }\n                else\n                {\n                    _2334 = (_2307 - _2274) / _2225;\n                }\n                tau += (_2175 * max(_2334, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2459);\n}\n\n",
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
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 10,
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_232",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 24,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_935",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 29,
                "offset": 0,
                "glsl_name": "fa_shadows"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1661",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10,
            "glsl_name": "fa_irr_tex_fa_env_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
          },
          {
            "slot": 8,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _302 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _787 = base_t;\n    _787.x = _225.x;\n    _787.y = _225.y;\n    _787.z = _225.z;\n    base_t = _787;\n    vec4 _241 = (_787 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _750 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _795 = _279;\n        _795.x = _284.x;\n        _795.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _795;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _798 = mrt;\n    _798.x = _313.x;\n    _798.y = _313.y;\n    _798.z = _313.z;\n    mrt = _798;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _755 = fa_mesh_fs_params[20].x;\n    float _756 = fa_mesh_fs_params[20].y;\n    float _759 = fa_mesh_fs_params[20].z;\n    float _758 = fa_mesh_fs_params[21].w;\n    float _761 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _755 *= _355.y;\n            _756 *= _355.z;\n            _758 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _750, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _755, _756, fa_mesh_fs_params[21].xyz, _758, _759, fa_mesh_fs_params[20].w, _761, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _661 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _661 = -_661;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 10,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 24,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _423 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_423, 1.0);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _787 = base_t;\n    _787.x = _225.x;\n    _787.y = _225.y;\n    _787.z = _225.z;\n    base_t = _787;\n    vec4 _241 = (_787 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _750 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _795 = _279;\n        _795.x = _284.x;\n        _795.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _795;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _798 = mrt;\n    _798.x = _313.x;\n    _798.y = _313.y;\n    _798.z = _313.z;\n    mrt = _798;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _755 = fa_mesh_fs_params[20].x;\n    float _756 = fa_mesh_fs_params[20].y;\n    float _759 = fa_mesh_fs_params[20].z;\n    float _758 = fa_mesh_fs_params[21].w;\n    float _761 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _755 *= _355.y;\n            _756 *= _355.z;\n            _758 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _750, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _755, _756, fa_mesh_fs_params[21].xyz, _758, _759, fa_mesh_fs_params[20].w, _761, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _661 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _661 = -_661;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 10,
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 24,
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
