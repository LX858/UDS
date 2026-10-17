document.addEventListener("DOMContentLoaded", (() => {
    const e = document.getElementById("propAttachContainer"),
        t = document.getElementById("animationSelect"),
        n = document.getElementById("animPrevBtn"),
        a = document.getElementById("animNextBtn"),
        o = document.getElementById("animFlagsInput"),
        d = document.getElementById("btnPlayAnim"),
        l = document.getElementById("btnStopAnim");
    let r = [],
        c = 0;
    const u = document.getElementById("propSelect1"),
        i = document.getElementById("prop1PrevBtn"),
        s = document.getElementById("prop1NextBtn"),
        p = document.getElementById("customProp1");
    let m = 0;
    const v = document.getElementById("propSelect2"),
        g = document.getElementById("prop2PrevBtn"),
        I = document.getElementById("prop2NextBtn"),
        E = document.getElementById("customProp2");
    let h = 0;
    const y = document.getElementById("boneSelect1"),
        B = document.getElementById("boneSelect2"),
        x = document.getElementById("rotationOrder1"),
        L = document.getElementById("rotationOrder2"),
        f = document.getElementById("btnResetAll"),
        b = document.getElementById("btnCloseUI"),
        C = document.getElementById("moveSpeedSlider"),
        S = document.getElementById("rotateSpeedSlider"),
        A = document.getElementById("moveSpeedValue"),
        k = document.getElementById("rotateSpeedValue"),
        P = document.getElementById("moveSpeedPresets"),
        D = document.getElementById("rotateSpeedPresets"),
        F = document.getElementById("cameraFocusSelect"),
        w = document.getElementById("camDistance"),
        N = document.getElementById("distanceValue"),
        T = document.getElementById("camAngle"),
        R = document.getElementById("angleValue"),
        M = document.getElementById("camHeight"),
        H = document.getElementById("heightValue"),
        $ = document.querySelectorAll(".camNudgeBtn");
    let q = [],
        O = null;

    function U(e, t) {
        document.querySelectorAll(e).forEach((e => {
            e.addEventListener("mousedown", (function() {
                O && clearInterval(O);
                const e = {};
                for (const t of this.attributes) t.name.startsWith("data-") && (e[t.name.slice(5)] = t.value);
                t(e), O = setInterval((() => {
                    t(e)
                }), 50)
            })), e.addEventListener("mouseup", (function() {
                O && (clearInterval(O), O = null)
            })), e.addEventListener("mouseleave", (function() {
                O && (clearInterval(O), O = null)
            }))
        }))
    }

    function V(e, t) {
        fetch(`https://${GetParentResourceName()}/${e}`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json; charset=UTF-8"
            },
            body: JSON.stringify(t)
        })
    }

    function j() {
        t.innerHTML = "", r.forEach(((e, n) => {
            const a = document.createElement("option");
            a.value = String(n), a.textContent = e.label, t.appendChild(a)
        })), c < 0 && (c = 0), c >= r.length && (c = 0), r.length > 0 && (t.value = String(c))
    }

    function G() {
        const e = document.getElementById("customAnimDict").value.trim(),
            t = document.getElementById("customAnimName").value.trim();
        if (e && t) {
            return V("setAnimation", {
                dict: e,
                anim: t,
                flags: parseInt(o.value) || 0
            }), void V("playAnim", {})
        }
        if (!r[c]) return;
        const n = r[c],
            a = parseInt(o.value) || 0;
        V("setAnimation", {
            dict: n.dict,
            anim: n.anim,
            flags: a
        }), V("playAnim", {})
    }

    function J(e) {
        const t = 1 === e ? u : v;
        let n = 1 === e ? m : h;
        t.innerHTML = "", q.forEach(((e, n) => {
            const a = document.createElement("option");
            a.value = String(n), a.textContent = e, t.appendChild(a)
        })), n < 0 && (n = q.length - 1), n >= q.length && (n = 0), q.length > 0 && (t.value = String(n)), 1 === e ? m = n : h = n
    }

    function W(e) {
        const t = q[1 === e ? m : h];
        t && V("spawnProp", {
            propIndex: e,
            modelName: t
        })
    }
    window.addEventListener("message", (t => {
            const n = t.data;
            "openUI" === n.type ? (e.style.display = "block", r = n.animations.slice(), c = 0, j(), y.innerHTML = "", B.innerHTML = "", n.bones.forEach((e => {
                const t = document.createElement("option");
                t.value = e.id, t.textContent = `${e.name} (${e.id})`, y.appendChild(t);
                const n = document.createElement("option");
                n.value = e.id, n.textContent = `${e.name} (${e.id})`, B.appendChild(n)
            })), y.options.length > 0 && (y.value = y.options[0].value, V("setBone", {
                propIndex: 1,
                boneId: parseInt(y.value)
            })), B.options.length > 0 && (B.value = B.options[0].value, V("setBone", {
                propIndex: 2,
                boneId: parseInt(B.value)
            })), q = n.props.slice(), m = 0, h = 0, J(1), J(2), C.value = n.moveSpeed.toString(), S.value = n.rotateSpeed.toString(), A.textContent = n.moveSpeed.toString(), k.textContent = n.rotateSpeed.toString(), P.innerHTML = "", n.defaultMoveSpeeds.forEach((e => {
                const t = document.createElement("button");
                t.className = "preset-button", t.textContent = e, t.addEventListener("click", (() => {
                    C.value = e, A.textContent = e, V("updateMoveSpeed", {
                        value: e
                    })
                })), P.appendChild(t)
            })), D.innerHTML = "", n.defaultRotateSpeeds.filter((e => e >= .5)).forEach((e => {
                const t = document.createElement("button");
                t.className = "preset-button", t.textContent = e, t.addEventListener("click", (() => {
                    S.value = e, k.textContent = e, V("updateRotateSpeed", {
                        value: e
                    })
                })), D.appendChild(t)
            })), F.value = n.cameraFocus || "ped", w.value = n.cameraDistance || "2.5", N.textContent = n.cameraDistance || "2.5", T.value = n.cameraAngle || "0", R.textContent = n.cameraAngle || "0", M.value = n.cameraHeight || "0.5", H.textContent = n.cameraHeight || "0.5") : "clipboard" === n.type ? (function(e) {
                const t = document.createElement("textarea");
                t.value = e, t.setAttribute("readonly", ""), t.style.position = "absolute", t.style.left = "-9999px", document.body.appendChild(t), t.select(), document.execCommand("copy"), document.body.removeChild(t)
            }(n.text), function(e, t, n) {
                const a = document.createElement("div");
                a.classList.add("notification", n), a.innerHTML = `<h4>${e}</h4><p>${t}</p>`, document.body.appendChild(a), setTimeout((() => {
                    a.classList.add("show")
                }), 10), setTimeout((() => {
                    a.classList.remove("show"), setTimeout((() => {
                        a.parentNode && document.body.removeChild(a)
                    }), 300)
                }), 3e3)
            }("Copied", "Data copied to clipboard", "success")) : "resetAllUI" === n.type && (y.options.length > 0 && (y.value = y.options[0].value, V("setBone", {
                propIndex: 1,
                boneId: parseInt(y.value)
            })), B.options.length > 0 && (B.value = B.options[0].value, V("setBone", {
                propIndex: 2,
                boneId: parseInt(B.value)
            })), F.value = "ped", w.value = "2.5", N.textContent = "2.5", T.value = "0", R.textContent = "0", M.value = "0.5", H.textContent = "0.5", c = 0, j(), m = 0, J(1), h = 0, J(2))
        })), n.addEventListener("click", (() => {
            0 !== r.length && (c = (c - 1 + r.length) % r.length, j(), G())
        })), a.addEventListener("click", (() => {
            0 !== r.length && (c = (c + 1) % r.length, j(), G())
        })), t.addEventListener("change", (() => {
            c = parseInt(t.value) || 0, document.getElementById("customAnimDict").value = "", document.getElementById("customAnimName").value = "", G()
        })), d.addEventListener("click", (() => {
            G()
        })), l.addEventListener("click", (() => {
            V("stopAnim", {})
        })), i.addEventListener("click", (() => {
            0 !== q.length && (m = (m - 1 + q.length) % q.length, J(1), W(1))
        })), s.addEventListener("click", (() => {
            0 !== q.length && (m = (m + 1) % q.length, J(1), W(1))
        })), g.addEventListener("click", (() => {
            0 !== q.length && (h = (h - 1 + q.length) % q.length, J(2), W(2))
        })), I.addEventListener("click", (() => {
            0 !== q.length && (h = (h + 1) % q.length, J(2), W(2))
        })), u.addEventListener("change", (() => {
            m = parseInt(u.value) || 0, W(1)
        })), v.addEventListener("change", (() => {
            h = parseInt(v.value) || 0, W(2)
        })), document.querySelectorAll(".spawnPropBtn").forEach((e => {
            e.addEventListener("click", (() => {
                const t = parseInt(e.getAttribute("data-propindex"));
                let n;
                n = 1 === t ? p.value.trim() || q[m] : E.value.trim() || q[h], n && V("spawnProp", {
                    propIndex: t,
                    modelName: n
                })
            }))
        })), document.querySelectorAll(".deletePropBtn").forEach((e => {
            e.addEventListener("click", (() => {
                V("deleteProp", {
                    propIndex: parseInt(e.getAttribute("data-propindex"))
                })
            }))
        })), y.addEventListener("change", (() => {
            V("setBone", {
                propIndex: 1,
                boneId: parseInt(y.value)
            })
        })), B.addEventListener("change", (() => {
            V("setBone", {
                propIndex: 2,
                boneId: parseInt(B.value)
            })
        })), x.addEventListener("change", (() => {
            V("setRotationOrder", {
                propIndex: 1,
                order: parseInt(x.value)
            })
        })), L.addEventListener("change", (() => {
            V("setRotationOrder", {
                propIndex: 2,
                order: parseInt(L.value)
            })
        })), C.addEventListener("input", (() => {
            A.textContent = C.value, V("updateMoveSpeed", {
                value: parseFloat(C.value)
            })
        })), S.addEventListener("input", (() => {
            k.textContent = S.value, V("updateRotateSpeed", {
                value: parseFloat(S.value)
            })
        })), F.addEventListener("change", (() => {
            console.log("Camera focus changed to: " + F.value), V("updateCameraFocus", {
                focus: F.value
            })
        })), w.addEventListener("input", (() => {
            N.textContent = w.value, V("updateCamera", {
                dist: parseFloat(w.value),
                angle: parseFloat(T.value),
                height: parseFloat(M.value)
            })
        })), T.addEventListener("input", (() => {
            R.textContent = T.value, V("updateCamera", {
                dist: parseFloat(w.value),
                angle: parseFloat(T.value),
                height: parseFloat(M.value)
            })
        })), M.addEventListener("input", (() => {
            H.textContent = M.value, V("updateCamera", {
                dist: parseFloat(w.value),
                angle: parseFloat(T.value),
                height: parseFloat(M.value)
            })
        })), $.forEach((e => {
            e.addEventListener("click", (() => {
                V("nudgeCamera", {
                    axis: e.getAttribute("data-axis"),
                    amount: parseFloat(e.getAttribute("data-amount"))
                })
            }))
        })), document.addEventListener("keydown", (n => {
            if ("Escape" === n.key && "block" === e.style.display) return e.style.display = "none", void V("closeUI", {});
            const a = document.activeElement;
            a === t && r.length > 0 ? "ArrowLeft" === n.key ? (n.preventDefault(), c = (c - 1 + r.length) % r.length, j(), G()) : "ArrowRight" === n.key && (n.preventDefault(), c = (c + 1) % r.length, j(), G()) : a === u && q.length > 0 ? "ArrowLeft" === n.key ? (n.preventDefault(), m = (m - 1 + q.length) % q.length, J(1), W(1)) : "ArrowRight" === n.key && (n.preventDefault(), m = (m + 1) % q.length, J(1), W(1)) : a === v && q.length > 0 && ("ArrowLeft" === n.key ? (n.preventDefault(), h = (h - 1 + q.length) % q.length, J(2), W(2)) : "ArrowRight" === n.key && (n.preventDefault(), h = (h + 1) % q.length, J(2), W(2)))
        })), document.querySelectorAll(".btnPos, .btnRot").forEach((e => {
            e.addEventListener("click", (() => {
                V("moveProp", {
                    propIndex: parseInt(e.getAttribute("data-propindex")),
                    direction: e.getAttribute("data-direction")
                })
            }))
        })), document.querySelectorAll(".flag-preset").forEach((e => {
            e.addEventListener("click", (() => {
                const t = e.getAttribute("data-value");
                o.value = t
            }))
        })), f.addEventListener("click", (() => {
            V("resetAll", {})
        })), b.addEventListener("click", (() => {
            e.style.display = "none", V("closeUI", {})
        })), document.getElementById("customBoneID1").addEventListener("change", (function() {
            const e = parseInt(this.value);
            e && V("setBone", {
                propIndex: 1,
                boneId: e
            })
        })), y.addEventListener("change", (() => {
            document.getElementById("customBoneID1").value = "", V("setBone", {
                propIndex: 1,
                boneId: parseInt(y.value)
            })
        })), document.getElementById("customBoneID2").addEventListener("change", (function() {
            const e = parseInt(this.value);
            e && V("setBone", {
                propIndex: 2,
                boneId: e
            })
        })), B.addEventListener("change", (() => {
            document.getElementById("customBoneID2").value = "", V("setBone", {
                propIndex: 2,
                boneId: parseInt(B.value)
            })
        })), document.querySelectorAll(".resetPropBtn").forEach((e => {
            e.addEventListener("click", (() => {
                V("resetProp", {
                    propIndex: parseInt(e.getAttribute("data-propindex"))
                })
            }))
        })), document.querySelectorAll(".copyDataBtn").forEach((e => {
            e.addEventListener("click", (() => {
                const t = parseInt(e.getAttribute("data-propindex")),
                    n = document.getElementById(`formatSelect${t}`);
                V("copyData", {
                    propIndex: t,
                    format: n ? n.value : "devcore"
                })
            }))
        }));
    const parseVec3 = s => {
        const m = s.match(/[-+]?[0-9]*\.?[0-9]+/g);
        if (!m || m.length < 3) return null;
        return [parseFloat(m[0]), parseFloat(m[1]), parseFloat(m[2])];
    };
    document.querySelectorAll(".applyOffsetBtn").forEach((e => {
        e.addEventListener("click", (() => {
            const t = parseInt(e.getAttribute("data-propindex"));
            const posRaw = document.getElementById("posVec" + t).value.trim();
            const rotRaw = document.getElementById("rotVec" + t).value.trim();
            const p = posRaw ? parseVec3(posRaw) : null;
            const r = rotRaw ? parseVec3(rotRaw) : null;
            if (!p && !r) return;
            const payload = { propIndex: t };
            if (p) { payload.px = p[0]; payload.py = p[1]; payload.pz = p[2]; }
            if (r) { payload.rx = r[0]; payload.ry = r[1]; payload.rz = r[2]; }
            V("setOffset", payload);
        }))
    })), U(".btnPos, .btnRot", (e => {
        V("moveProp", {
            propIndex: parseInt(e.propindex),
            direction: e.direction
        })
    })), U(".camNudgeBtn", (e => {
        V("nudgeCamera", {
            axis: e.axis,
            amount: parseFloat(e.amount)
        })
    }))
}));