import numpy as np
import matplotlib.pyplot as plt
from scipy.ndimage import convolve1d

# Set random seed
seed = 1
np.random.seed(seed)

# Parameters
N = 64  # Number of neurons
Nit = 50  # Number of learning iterations
K = 0.001 / 2  # Gain error during learning
Ntime = 15000  # Number of time points
lambdaV = 50  # Leak of membrane potential
lambda_slow = 10  # Leak of slow connections
dt = 0.0001
gainD = 1 / N / 2  # Gain of decoder D
eta_W = 0.3  # Learning rate
nzMemb = 0.0001  # Small noise
mu = 0.4167 * 1 / N ** 2  # L2 cost
nu = 0.0083 * 1 / N ** 2  # L1 cost
amplitudC = 1
amplitudCg = 1
frac1 = 0.03
frac2 = 0.3
gainc = 300 * 2
dynprm = 8  # k/m
Ninput = 2  # Number of dimensions of the desired dynamics

# Define desired dynamics
def desired_dyn(x, c, dynprm):
    return 3 * np.array([-dynprm * x[1] - x[0], x[0]]) * dt + c

# Initialize weights and thresholds
D = np.random.randn(Ninput, N) * gainD
Wf = -(D.T @ D + mu * np.eye(N))
W = np.zeros((N, N))
thres = np.diag(D.T @ D) / 2 + mu / 2 + nu / 2

# Helper function to generate random commands
def gen_rand_cmd(Ninput, Ntime, gainc, dt, frac1, frac2):
    assert frac1 <= frac2
    c = np.random.randn(Ninput, Ntime) * gainc * dt
    w = np.exp(-np.arange(0, 5000 * 2.5) / 100)
    w /= np.sum(w)
    for i in range(Ninput):
        c[i, :] = convolve1d(c[i, :], w, mode='constant')
        c[i, :] = convolve1d(c[i, :], w, mode='constant')
    zidx1 = int(frac1 * Ntime)
    zidx2 = int(frac2 * Ntime)
    c[0, :zidx1] = 0
    c[0, zidx2:] = 0
    if Ninput > 1:
        c[1:] = 0
    return c

# Network simulation
def run_network(learnflg, D, Wf, W, thres, dt, N, Ninput, Ntime, K, gainD, lambda_slow, eta_W, amplitudC, gainc, frac1, frac2, dynprm, lambdaV, desired_dyn, nzMemb):
    V = np.zeros((N, Ntime))
    O = np.zeros((N, Ntime), dtype=bool)
    rO = np.zeros((N, Ntime))
    x = np.zeros((Ninput, Ntime))
    xest = np.zeros((Ninput, Ntime))
    e = np.zeros((Ninput, Ntime))
    c = amplitudC * gen_rand_cmd(Ninput, Ntime, gainc, dt, frac1, frac2)
    if not learnflg:
        K = 0
    for t in range(Ntime - 1):
        V[:, t + 1] = (
            (1 - lambdaV * dt) * V[:, t]
            + D.T @ c[:, t]
            + Wf @ O[:, t]
            + W @ rO[:, t] * dt
            + nzMemb * np.random.randn(N) * gainD ** 2
            + K * D.T @ e[:, t]
        )
        O[:, t + 1] = V[:, t + 1] > thres
        if np.sum(O[:, t + 1]) > 1:
            u = V[:, t + 1] - thres
            O[:, t + 1] = False
            O[np.argmax(u), t + 1] = True
        if t > 1006 and learnflg:
            W += eta_W * dt * np.outer(rO[:, t], D.T @ e[:, t])
        rO[:, t + 1] = (1 - lambda_slow * dt) * rO[:, t] + O[:, t + 1]
        x[:, t + 1] = x[:, t] + desired_dyn(x[:, t], c[:, t], dynprm)
        xest[:, t + 1] = (1 - lambda_slow * dt) * xest[:, t] + D @ O[:, t + 1]
        e[:, t + 1] = x[:, t + 1] - xest[:, t + 1]
    return x, xest, O, e, W, c, rO, V

# Learning
trainerr = np.zeros(Nit)
for it in range(1, Nit + 1):
    learnflg = 1
    x, xest, O, e, W, c, rO, V = run_network(learnflg, D, Wf, W, thres, dt, N, Ninput, Ntime, K, gainD, lambda_slow, eta_W, amplitudC, gainc, frac1, frac2, dynprm, lambdaV, desired_dyn, nzMemb)
    normx = np.sum(x ** 2)
    trainerr[it - 1] = np.sum(np.sum(e ** 2, axis=0)) / normx
    magW = np.sqrt(np.sum(W ** 2))
    print(f"it={it}, trainerr={trainerr[it - 1]:.5f}, maxW={np.max(W):.5f}, magW={magW:.5f}, sum_spikes={np.sum(O) / 1000:.1f}")

# Plot learning curve
smoothwndw = 30
trainerr_smooth = np.convolve(trainerr, np.ones(smoothwndw) / smoothwndw, mode='valid')
plt.figure()
plt.plot(trainerr_smooth, linewidth=3)
plt.xlabel("Learning iteration")
plt.ylabel("Normalized error")
plt.title("Learning curve")
plt.show()

# Test generalization
learnflg = 0
xG, xestG, OG, eG, _, cG, rOG, VG = run_network(
    learnflg, D, Wf, W, thres, dt, N, Ninput, Ntime, K, gainD, lambda_slow, eta_W,
    amplitudCg, gainc, frac1, frac2, dynprm, lambdaV, desired_dyn, nzMemb
)

# Time array
T = np.arange(Ntime) * dt

# Plot generalization results
plt.figure(figsize=(12, 8))

# Desired vs predicted trajectory
plt.subplot(2, 1, 1)
for i in range(Ninput):
    plt.plot(T, xG[i, :], '--', linewidth=2, label=f'Desired x[{i}]')
    plt.plot(T, xestG[i, :], '-', linewidth=1, label=f'Predicted x[{i}]')
plt.title('Desired trajectory (--) vs. predicted trajectory (-)', fontsize=25)
plt.xlabel('Time (s)', fontsize=15)
plt.ylabel('Value', fontsize=15)
plt.legend(fontsize=12)
plt.grid(True)

# Spike raster
plt.subplot(2, 1, 2)
spike_indices, spike_times = np.where(OG.T)
plt.scatter(spike_times * dt, spike_indices, s=10, c='k', marker='.')
plt.title('Spike raster', fontsize=25)
plt.xlabel('Time (s)', fontsize=15)
plt.ylabel('Neuron Index', fontsize=15)
plt.ylim([-2, N])
plt.yticks([1, N // 2, N])
plt.grid(True)

plt.tight_layout()
plt.show()
